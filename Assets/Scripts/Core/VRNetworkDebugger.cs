using UnityEngine;
using System.Collections.Generic;

namespace Core
{
    public class VRNetworkDebugger : MonoBehaviour
    {
        [SerializeField] private bool logToConsole = true;
        // In the future, this can point to a localhost server address
        
        private void OnEnable()
        {
            Application.logMessageReceived += HandleLog;
            Debug.Log("[VRNetworkDebugger] Debugger Attached");
        }

        private void OnDisable()
        {
            Application.logMessageReceived -= HandleLog;
        }

        private void HandleLog(string logString, string stackTrace, LogType type)
        {
            if (!logToConsole) return;

            // This structure captures the log. 
            // TODO: Extend this to write to a local file or send via HTTP/UDP to an external console.
            
            // For now, we rely on the editor console, but this hook is ready for the "Terminal Streaming" requirement.
        }
    }
}
