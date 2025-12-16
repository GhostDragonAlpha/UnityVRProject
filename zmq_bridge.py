import zmq
import sys
import time
import game_state_pb2

class UnityZeroMQClient:
    def __init__(self, addr="tcp://127.0.0.1:5555"):
        self.context = zmq.Context()
        self.socket = self.context.socket(zmq.REQ)
        print(f"[ZMQ] Connecting to Unity on {addr}...")
        self.socket.connect(addr)
    
    def send_command(self, cmd_msg):
        try:
            # Serialize
            data = cmd_msg.SerializeToString()
            # Send
            self.socket.send(data)
            
            # Receive Reply (GameStateMsg)
            reply_data = self.socket.recv()
            state = game_state_pb2.GameStateMsg()
            state.ParseFromString(reply_data)
            return state
        except zmq.ZMQError as e:
            print(f"[ZMQ] Error: {e}")
            return None

    def destroy_object(self, name):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "destroy"
        cmd.target = name
        return self.send_command(cmd)

    def generate_universe(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "generate_universe"
        return self.send_command(cmd)
        
    def set_transform(self, name, x, y, z):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "set_transform"
        cmd.target = name
        # Vector3Msg
        cmd.vector_payload.x = x
        cmd.vector_payload.y = y
        cmd.vector_payload.z = z
        return self.send_command(cmd)

    def run_physics_test(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "run_test"
        return self.send_command(cmd)

    def get_hierarchy(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "get_hierarchy"
        return self.send_command(cmd)

    def save_game(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "save_game"
        return self.send_command(cmd)

    def load_game(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "load_game"
        return self.send_command(cmd)

    def check_components(self, name):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "check_components"
        cmd.target = name
        return self.send_command(cmd)

    def init_universe(self):
        cmd = game_state_pb2.CommandMsg()
        cmd.action = "init_universe"
        return self.send_command(cmd)


if __name__ == "__main__":
    client = UnityZeroMQClient()
    
    if len(sys.argv) > 1:
        cmd = sys.argv[1]
        
        reply = None
        if cmd == "destroy" and len(sys.argv) > 2:
            reply = client.destroy_object(sys.argv[2])
        
        elif cmd == "generate_universe":
            reply = client.generate_universe()
            
        elif cmd == "check_hierarchy":
            reply = client.get_hierarchy()

        elif cmd == "save_game":
             reply = client.save_game()
        
        elif cmd == "load_game":
             reply = client.load_game()

        elif cmd == "check_components" and len(sys.argv) > 2:
             reply = client.check_components(sys.argv[2])

        elif cmd == "init_universe":
             reply = client.init_universe()
            
        elif cmd == "run_test":
             reply = client.run_physics_test()
             
        elif cmd == "set_pos" and len(sys.argv) > 4:
            reply = client.set_transform(sys.argv[2], float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]))
        
        else:
            print(f"Unknown command: {cmd}")

        if reply:
            print(f"Reply Status: {reply.status}")
            for e in reply.entities:
                print(f"Entity: {e.name} pos: ({e.position.x:.1f}, {e.position.y:.1f}, {e.position.z:.1f}) rot: ({e.rotation.x:.1f}, {e.rotation.y:.1f}, {e.rotation.z:.1f})")
