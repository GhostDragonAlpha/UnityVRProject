using UnityEngine;

namespace Core
{
    public class GameManager : MonoBehaviour
    {
        public static GameManager Instance { get; private set; }

        public enum GameState
        {
            Menu,
            Playing,
            Paused
        }

        public GameState CurrentState { get; private set; }

        private void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        private void Start()
        {
            SetState(GameState.Menu);
            Debug.Log("[GameManager] Initialized in Menu State");
        }

        public void SetState(GameState newState)
        {
            CurrentState = newState;
            // TODO: Dispatch events for state changes
            Debug.Log($"[GameManager] State changed to {newState}");
        }
    }
}
