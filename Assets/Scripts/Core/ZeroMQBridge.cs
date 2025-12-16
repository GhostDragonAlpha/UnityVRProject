using UnityEngine;
using NetMQ;
using NetMQ.Sockets;
using System.Collections.Concurrent;
using System.Threading;
using Google.Protobuf;
using Core.Network; 

namespace Core
{
    // Replaces AgentBridge.cs
    // Uses NetMQ (ZeroMQ) for high-speed command processing.
    [ExecuteAlways]
    public class ZeroMQBridge : MonoBehaviour
    {
        private ResponseSocket server;
        private Thread serverThread;
        private bool running = false;
        
        // Command Queue for Main Thread
        private ConcurrentQueue<byte[]> commandQueue = new ConcurrentQueue<byte[]>();
        private ConcurrentQueue<byte[]> replyQueue = new ConcurrentQueue<byte[]>();
        
        private void OnEnable()
        {
            StartServer();
#if UNITY_EDITOR
            UnityEditor.EditorApplication.update += Update;
#endif
        }

        private void OnDisable()
        {
            StopServer();
#if UNITY_EDITOR
            UnityEditor.EditorApplication.update -= Update;
#endif
        }

        private void StartServer()
        {
            if (running) return;
            running = true;
            serverThread = new Thread(ServerLoop);
            serverThread.IsBackground = true;
            serverThread.Start();
            Debug.Log("[ZeroMQ] Bridge Server Started on tcp://127.0.0.1:5555");
        }

        private void StopServer()
        {
            running = false;
            // Force socket close if blocked?
            // NetMQ cleanup...
            if (server != null)
            {
                try { server.Close(); server.Dispose(); } catch {}
            }
            if (serverThread != null) serverThread.Join(500);
            NetMQConfig.Cleanup(); // Can be dangerous if other threads use it, but safe here.
            Debug.Log("[ZeroMQ] Server Stopped.");
        }

        private void ServerLoop()
        {
            AsyncIO.ForceDotNet.Force();
            using (server = new ResponseSocket("@tcp://127.0.0.1:5555"))
            {
                while (running)
                {
                    // Receive (Blocking)
                    // Use TryReceive to allow loop exit?
                    byte[] messageBytes;
                    if (server.TryReceiveFrameBytes(System.TimeSpan.FromSeconds(0.1), out messageBytes))
                    {
                        // Enqueue to Main Thread
                        commandQueue.Enqueue(messageBytes);
                        
                        // Wait for Reply from Main Thread
                        byte[] reply = null;
                        int timeout = 200; // 1s (5ms * 200)
                        while (running && timeout-- > 0)
                        {
                            if (replyQueue.TryDequeue(out reply))
                            {
                                server.SendFrame(reply);
                                break;
                            }
                            Thread.Sleep(5); // 5ms polling
                        }
                        
                        if (reply == null && running)
                        {
                            // Timeout / Error
                            var err = new GameStateMsg { Status = "error: timeout" };
                            server.SendFrame(err.ToByteArray());
                        }
                    }
                }
            }
        }

        private void Update()
        {
            ProcessCommandQueue();
            
            // Force Gravity Alignment in Editor
            if (!Application.isPlaying)
            {
                if (Core.PhysicsEngine.Instance == null)
                {
                     Core.PhysicsEngine.Instance = FindFirstObjectByType<Core.PhysicsEngine>();
                }

                var align = FindFirstObjectByType<Player.GravityAlignment>();
                Debug.Log($"[Bridge] Update. Align found: {align != null}. Physics: {Core.PhysicsEngine.Instance != null}");
                if (align) 
                {
                    align.ManualUpdate(Time.deltaTime);
                }
                else
                {
                     // Try finding differently?
                     var obj = GameObject.Find("PlayerShip");
                     if (obj) 
                     {
                         align = obj.GetComponent<Player.GravityAlignment>();
                         if (align) align.ManualUpdate(Time.deltaTime);
                     }
                }
            }
        }

        private void ProcessCommandQueue()
        {
            if (commandQueue.TryDequeue(out byte[] data))
            {
                byte[] response = ProcessCommand(data);
                replyQueue.Enqueue(response);
            }
        }

        private byte[] ProcessCommand(byte[] data)
        {
            var reply = new GameStateMsg { Timestamp = Time.time, Status = "ok" };
            
            try
            {
                var cmd = CommandMsg.Parser.ParseFrom(data);
                
                if (cmd.Action == "destroy")
                {
                    GameObject obj = GameObject.Find(cmd.Target);
                    if (obj) 
                    {
                        DestroyImmediate(obj);
                    }
                    else
                    {
                         reply.Status = "error: not found";
                    }
                }
                else if (cmd.Action == "generate_universe")
                {
                    // Find UniverseGenerator
                    // Deprecated warning ignored for now as we want functional code
                    var gen = FindFirstObjectByType<Procedural.UniverseGenerator>();
                    if (gen) gen.GenerateOrigin();
                }
                else if (cmd.Action == "set_transform")
                {
                     GameObject obj = GameObject.Find(cmd.Target);
                     if (obj && cmd.VectorPayload != null)
                     {
                         var newPos = new Vector3d(cmd.VectorPayload.X, cmd.VectorPayload.Y, cmd.VectorPayload.Z);
                         Debug.Log($"[ZeroMQ] SetTransform {cmd.Target} to {newPos}");
                         
                         // 1. Check WorldMover (Player/Camera Origin)
                         var wm = obj.GetComponent<WorldMover>();
                         if (wm != null)
                         {
                             wm.VirtualPosition = newPos;
                             // Force update
                             wm.SendMessage("LateUpdate", SendMessageOptions.DontRequireReceiver);
                         }
                         // 2. Check VirtualTransform (Networked/Large Scale Objects)
                         else 
                         {
                             var vt = obj.GetComponent<VirtualTransform>();
                             if (vt != null)
                             {
                                 vt.WorldPosition = newPos;
                             }
                             
                             // 3. Fallback to Unity Transform (Visual/Physics Local)
                             // Note: If VT exists, WorldMover will likely overwrite this next frame, 
                             // but setting VT above fixes that.
                             // For non-VT objects, this moves them.
                             obj.transform.position = newPos.ToVector3();
                         }
                     }
                     else
                     {
                         reply.Status = "error: not found or invalid payload";
                     }
                }
                else if (cmd.Action == "init_universe")
                {
                    var gen = FindFirstObjectByType<Procedural.UniverseGenerator>();
                    if (gen)
                    {
                        gen.GenerateOrigin();
                        reply.Status = "ok: universe generated";
                    }
                    else
                    {
                        var root = GameObject.Find("GameRoot");
                        if (root) 
                        {
                            gen = root.AddComponent<Procedural.UniverseGenerator>();
                            gen.GenerateOrigin();
                            reply.Status = "ok: universe created and generated";
                        }
                        else reply.Status = "error: no gameroot";
                    }
                }
                else if (cmd.Action == "check_components")
                {
                    GameObject obj = GameObject.Find(cmd.Target);
                    if (obj)
                    {
                        var comps = obj.GetComponents<Component>();
                        string list = "";
                        foreach(var c in comps) list += c.GetType().Name + ", ";
                        reply.Status = "ok: " + list;
                    }
                    else reply.Status = "error: not found";
                }
                else if (cmd.Action == "run_test")
                {
                     // Find PhysicsVerifier
                     var verifier = FindFirstObjectByType<Testing.PhysicsVerifier>();
                     if (verifier)
                     {
                         verifier.RunTestSeries();
                         reply.Status = "ok: test triggered";
                     }
                     else
                     {
                         reply.Status = "error: verifier not found";
                     }
                }
                 else if (cmd.Action == "get_hierarchy")
                {
                    AddEntityToState(reply, GameObject.Find("GameRoot"));
                    
                    var earth = FindFirstObjectByType<Core.Planet>();
                    if (earth) AddEntityToState(reply, earth.gameObject);
                    else AddEntityToState(reply, GameObject.Find("Earth")); // Fallback

                    var playerAlign = FindFirstObjectByType<Player.GravityAlignment>();
                    if (playerAlign) 
                    {
                        AddEntityToState(reply, playerAlign.gameObject);
                        // Rename it to "ThePlayer" in the message if needed, or just keep its name
                    }
                    else 
                    {
                        AddEntityToState(reply, GameObject.Find("PlayerShip"));
                        AddEntityToState(reply, GameObject.Find("Player"));
                    }
                }
                /*
                else if (cmd.Action == "save_game")
                {
                     // Disabled for Physics Verification
                     // var saveMgr = FindFirstObjectByType<Gameplay.Persistence.SaveManager>();
                     // ...
                     reply.Status = "error: temporary disabled";
                }
                else if (cmd.Action == "load_game")
                {
                     // Disabled
                     reply.Status = "error: temporary disabled";
                }
                */
            }
            catch (System.Exception e)
            {
                reply.Status = "error: " + e.Message;
            }
            
            return reply.ToByteArray();
        }
        
        private void AddEntityToState(GameStateMsg state, GameObject obj)
        {
            if (obj == null) return;
            var tMsg = new TransformMsg();
            tMsg.Name = obj.name;
            var pos = obj.transform.position;
            tMsg.Position = new Vector3Msg { X = pos.x, Y = pos.y, Z = pos.z };
            state.Entities.Add(tMsg);
        }
    }
}
