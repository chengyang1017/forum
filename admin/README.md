# Glyphora Admin

Administrative and moderation console for Glyphora.

## Stack

- React
- TypeScript
- Vite
- React Router
- TanStack Query
- Ant Design
- Firebase Authentication
- Axios

## Responsibilities

- Administrator authentication
- Server-side administrator authorization
- Moderation dashboard
- Report status statistics
- Report filtering
- Report review drawer
- Administrator notes
- Report status transitions
- Cursor-based report pagination

## Architecture

React Admin
-> Firebase ID token
-> Node.js / Express API
-> requireAuth
-> requireAdmin
-> Prisma
-> PostgreSQL

Firebase Authentication identifies the signed-in user.

Administrator authorization is determined by the backend user role stored in PostgreSQL. Client-side route protection is only a UI guard and is not the security boundary.

## Development

Install dependencies:

    npm install

Start development:

    npm run dev

Run lint:

    npm run lint

Build production bundle:

    npm run build

## Environment

Create admin/.env based on .env.example.

Required variables:

    VITE_API_BASE_URL
    VITE_FIREBASE_API_KEY
    VITE_FIREBASE_AUTH_DOMAIN
    VITE_FIREBASE_PROJECT_ID
    VITE_FIREBASE_STORAGE_BUCKET
    VITE_FIREBASE_MESSAGING_SENDER_ID
    VITE_FIREBASE_APP_ID

The local .env file is ignored by Git.

## Moderation statuses

- pending: awaiting review
- reviewed: reviewed by an administrator
- dismissed: no moderation action required
- actioned: moderation decision recorded

actioned currently records the moderation decision only. It does not delete or hide the reported post.
