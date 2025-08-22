# Tech Stack

## Context

Global tech stack defaults for Agent OS projects, overridable in project-specific `.agent-os/product/tech-stack.md`.

- Language: TypeScript latest stable
- JavaScript Framework: React latest stable
- Build Tool: bun build
- Import Strategy: Node.js modules
- Package Manager: bun
- Node Version: 22 LTS
- CSS Framework: Tailwind CSS latest stable
- UI Components: shadcn/ui
- UI Installation: Manually
- Font Provider: Google Fonts
- Font Loading: Self-hosted for performance
- Icons: Lucide React components
- State Management: React Context API + useReducer for complex state
- HTTP Client: Fetch API with TanStack Query
- Routing: TanStack Router
- Testing: bun test + React Testing Library
- Linting: ESLint with React hooks plugin
- Code Formatting: Prettier
- Development Server: bun --watch
- Component Architecture: Functional components with hooks
