# Smart Home Backend (Local Docker Starter)

This starter runs:
- Eclipse Mosquitto (MQTT broker)  
- Node.js backend (REST + WebSocket + MQTT client)

Quick start:
1. Copy `.env.example` to `backend/.env` and edit if needed.
2. From repository root run:
   docker-compose up --build

Backend endpoints:
- POST /auth/login  -> { username, password } returns JWT
- GET /devices (requires Authorization: Bearer <token>)
- POST /devices/:id/command (requires Authorization) -> publishes MQTT to topic `home/{id}/set`
- WebSocket at ws://<host>:3000/ws forwards MQTT messages to connected clients

Test:
- Login with POST http://localhost:3000/auth/login  
  Body: { "username": "admin", "password": "password123" }

- WebSocket: ws://localhost:3000/ws  
  Send: {"type":"subscribe","topic":"home/+/status"} to set subscription filter.

Notes:
- This is a minimal dev setup. For production, secure Mosquitto with passwords/TLS, use a proper DB, validate inputs, and add error handling and logging.