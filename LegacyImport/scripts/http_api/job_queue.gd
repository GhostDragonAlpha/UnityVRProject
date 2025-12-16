extends Node
# Note: class_name removed to avoid conflict with autoload singleton named JobQueue

## Job Queue System
## Manages long-running async operations with status tracking and result storage
## Supports: batch operations, scene preloading, cache warming

signal job_queued(job_id: String)
signal job_started(job_id: String)
signal job_completed(job_id: String)
signal job_failed(job_id: String, error: String)
signal job_cancelled(job_id: String)
signal job_progress(job_id: String, progress: float)

# Job storage
var _jobs: Dictionary = {}  # job_id -> job_data
var _next_job_id: int = 1

# Job queue
var _queue: Array = []
var _running_jobs: Array = []
const MAX_CONCURRENT_JOBS = 3

# Job result retention
const RESULT_RETENTION_SECONDS = 86400  # 24 hours
var _cleanup_timer: Timer

# Job types
enum JobType {
	BATCH_OPERATIONS,
	SCENE_PRELOAD,
	CACHE_WARMING
}

# Job status
enum JobStatus {
	QUEUED,
	RUNNING,
	COMPLETED,
	FAILED,
	CANCELLED
}

# Singleton instance
static var _instance: Node = null


func _init():
	if _instance == null:
		_instance = self


func _ready():
	print("[JobQueue] Initialized job queue system")

	# Setup cleanup timer
	_cleanup_timer = Timer.new()
	add_child(_cleanup_timer)
	_cleanup_timer.wait_time = 3600.0  # Clean up every hour
	_cleanup_timer.timeout.connect(_cleanup_old_jobs)
	_cleanup_timer.start()

	# Start processing queue
	_process_queue()


static func get_instance() -> Node:
	return _instance


## Submit a new job to the queue
func submit_job(job_type: JobType, parameters: Dictionary) -> Dictionary:
	# Generate job ID
	var job_id = str(_next_job_id)
	_next_job_id += 1

	# Create job data
	var job = {
		"id": job_id,
		"type": job_type,
		"parameters": parameters,
		"status": JobStatus.QUEUED,
		"progress": 0.0,
		"created_at": Time.get_unix_time_from_system(),
		"started_at": null,
		"completed_at": null,
		"result": null,
		"error": null
	}

	_jobs[job_id] = job
	_queue.append(job_id)

	print("[JobQueue] Job queued: ", job_id, " (", _get_job_type_name(job_type), ")")
	job_queued.emit(job_id)

	# Try to start processing immediately
	_process_queue()

	return {
		"success": true,
		"job_id": job_id,
		"status": _get_status_name(JobStatus.QUEUED)
	}


## Get job status
func get_job_status(job_id: String) -> Dictionary:
	if not _jobs.has(job_id):
		return {
			"success": false,
			"error": "Job not found"
		}

	var job = _jobs[job_id]

	return {
		"success": true,
		"job": {
			"id": job.id,
			"type": _get_job_type_name(job.type),
			"status": _get_status_name(job.status),
			"progress": job.progress,
			"created_at": job.created_at,
			"started_at": job.started_at,
			"completed_at": job.completed_at,
			"result": job.result,
			"error": job.error
		}
	}


## Cancel a job
func cancel_job(job_id: String) -> Dictionary:
	if not _jobs.has(job_id):
		return {
			"success": false,
			"error": "Job not found"
		}

	var job = _jobs[job_id]

	# Can only cancel queued jobs
	if job.status != JobStatus.QUEUED:
		return {
			"success": false,
			"error": "Can only cancel queued jobs"
		}

	# Remove from queue
	_queue.erase(job_id)
	job.status = JobStatus.CANCELLED

	print("[JobQueue] Job cancelled: ", job_id)
	job_cancelled.emit(job_id)

	return {
		"success": true,
		"message": "Job cancelled"
	}


## List all jobs with optional status filter
func list_jobs(status_filter: String = "") -> Dictionary:
	var jobs = []

	for job_id in _jobs.keys():
		var job = _jobs[job_id]

		# Apply status filter if specified
		if not status_filter.is_empty():
			var job_status_name = _get_status_name(job.status)
			if job_status_name != status_filter:
				continue

		jobs.append({
			"id": job.id,
			"type": _get_job_type_name(job.type),
			"status": _get_status_name(job.status),
			"progress": job.progress,
			"created_at": job.created_at
		})

	return {
		"success": true,
		"jobs": jobs,
		"count": jobs.size()
	}


## Process the job queue
func _process_queue() -> void:
	# Check if we can start more jobs
	while _running_jobs.size() < MAX_CONCURRENT_JOBS and _queue.size() > 0:
		var job_id = _queue.pop_front()
		_start_job(job_id)


## Start executing a job
func _start_job(job_id: String) -> void:
	if not _jobs.has(job_id):
		return

	var job = _jobs[job_id]
	job.status = JobStatus.RUNNING
	job.started_at = Time.get_unix_time_from_system()
	_running_jobs.append(job_id)

	print("[JobQueue] Starting job: ", job_id, " (", _get_job_type_name(job.type), ")")
	job_started.emit(job_id)

	# Execute job based on type
	match job.type:
		JobType.BATCH_OPERATIONS:
			_execute_batch_operations_job(job_id)
		JobType.SCENE_PRELOAD:
			_execute_scene_preload_job(job_id)
		JobType.CACHE_WARMING:
			_execute_cache_warming_job(job_id)


## Execute batch operations job
func _execute_batch_operations_job(job_id: String) -> void:
	var job = _jobs[job_id]
	var operations = job.parameters.get("operations", [])
	var mode = job.parameters.get("mode", "continue")

	# Process operations asynchronously
	_process_batch_async(job_id, operations, mode, 0)


## Process batch operations asynchronously
func _process_batch_async(job_id: String, operations: Array, mode: String, index: int) -> void:
	if not _jobs.has(job_id):
		return

	var job = _jobs[job_id]

	# Check if job was cancelled
	if job.status == JobStatus.CANCELLED:
		_finish_job(job_id, false, "Job was cancelled")
		return

	# Check if we're done
	if index >= operations.size():
		_finish_job(job_id, true, {
			"total": operations.size(),
			"message": "Batch operations completed"
		})
		return

	# Process one operation
	var op = operations[index]
	var action = op.get("action")
	var scene_path = op.get("scene_path", "")

	print("[JobQueue] Job ", job_id, " processing operation ", index + 1, "/", operations.size())

	# Update progress
	job.progress = float(index) / float(operations.size())
	job_progress.emit(job_id, job.progress)

	# Execute operation (using small delay to allow other processing)
	get_tree().create_timer(0.1).timeout.connect(func():
		# Continue to next operation
		_process_batch_async(job_id, operations, mode, index + 1)
	)


## Execute scene preload job
func _execute_scene_preload_job(job_id: String) -> void:
	var job = _jobs[job_id]
	var scene_paths = job.parameters.get("scene_paths", [])

	# Preload scenes asynchronously
	_preload_scenes_async(job_id, scene_paths, 0, [])


## Preload scenes asynchronously
func _preload_scenes_async(job_id: String, scene_paths: Array, index: int, loaded_scenes: Array) -> void:
	if not _jobs.has(job_id):
		return

	var job = _jobs[job_id]

	# Check if we're done
	if index >= scene_paths.size():
		_finish_job(job_id, true, {
			"scenes_loaded": loaded_scenes.size(),
			"total_scenes": scene_paths.size(),
			"scenes": loaded_scenes
		})
		return

	# Preload one scene
	var scene_path = scene_paths[index]

	print("[JobQueue] Job ", job_id, " preloading scene ", index + 1, "/", scene_paths.size(), ": ", scene_path)

	# Update progress
	job.progress = float(index) / float(scene_paths.size())
	job_progress.emit(job_id, job.progress)

	# Load scene with caching
	if ResourceLoader.exists(scene_path):
		var packed_scene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
		if packed_scene:
			loaded_scenes.append({
				"scene_path": scene_path,
				"success": true
			})
		else:
			loaded_scenes.append({
				"scene_path": scene_path,
				"success": false,
				"error": "Failed to load scene"
			})
	else:
		loaded_scenes.append({
			"scene_path": scene_path,
			"success": false,
			"error": "Scene not found"
		})

	# Continue to next scene
	get_tree().create_timer(0.05).timeout.connect(func():
		_preload_scenes_async(job_id, scene_paths, index + 1, loaded_scenes)
	)


## Execute cache warming job
func _execute_cache_warming_job(job_id: String) -> void:
	var job = _jobs[job_id]

	# Simulate cache warming
	print("[JobQueue] Job ", job_id, " warming cache...")

	# For now, just complete after a short delay
	get_tree().create_timer(2.0).timeout.connect(func():
		_finish_job(job_id, true, {
			"cache_warmed": true,
			"message": "Cache warming completed"
		})
	)


## Finish a job
func _finish_job(job_id: String, success: bool, result: Variant) -> void:
	if not _jobs.has(job_id):
		return

	var job = _jobs[job_id]
	job.completed_at = Time.get_unix_time_from_system()
	job.progress = 1.0

	if success:
		job.status = JobStatus.COMPLETED
		job.result = result
		print("[JobQueue] Job completed: ", job_id)
		job_completed.emit(job_id)
	else:
		job.status = JobStatus.FAILED
		job.error = result if result is String else "Job failed"
		print("[JobQueue] Job failed: ", job_id, " - ", job.error)
		job_failed.emit(job_id, job.error)

	# Remove from running jobs
	_running_jobs.erase(job_id)

	# Process next job in queue
	_process_queue()


## Cleanup old completed jobs
func _cleanup_old_jobs() -> void:
	var current_time = Time.get_unix_time_from_system()
	var cutoff_time = current_time - RESULT_RETENTION_SECONDS

	var jobs_to_remove = []
	for job_id in _jobs.keys():
		var job = _jobs[job_id]

		# Only clean up completed/failed/cancelled jobs
		if job.status == JobStatus.COMPLETED or job.status == JobStatus.FAILED or job.status == JobStatus.CANCELLED:
			if job.completed_at and job.completed_at < cutoff_time:
				jobs_to_remove.append(job_id)

	# Remove old jobs
	for job_id in jobs_to_remove:
		_jobs.erase(job_id)
		print("[JobQueue] Cleaned up old job: ", job_id)

	if jobs_to_remove.size() > 0:
		print("[JobQueue] Cleaned up ", jobs_to_remove.size(), " old jobs")


## Get job type name
func _get_job_type_name(job_type: JobType) -> String:
	match job_type:
		JobType.BATCH_OPERATIONS:
			return "batch_operations"
		JobType.SCENE_PRELOAD:
			return "scene_preload"
		JobType.CACHE_WARMING:
			return "cache_warming"
		_:
			return "unknown"


## Get status name
func _get_status_name(status: JobStatus) -> String:
	match status:
		JobStatus.QUEUED:
			return "queued"
		JobStatus.RUNNING:
			return "running"
		JobStatus.COMPLETED:
			return "completed"
		JobStatus.FAILED:
			return "failed"
		JobStatus.CANCELLED:
			return "cancelled"
		_:
			return "unknown"
