# Supabase Auth Flutter App

A Flutter application demonstrating authentication with Supabase, following the MVC (Model-View-Controller) pattern and using GetX for state management and navigation.

## Features

- Email/password authentication
- Google Sign-In integration
- User profile display
- Session persistence
- MVC architecture
- Document upload and management
- Automatic document categorization using OpenAI
- Tag-based document organization
- Neomorphic UI design

## Setup Instructions

1. **Create a Supabase project**
   - Go to [Supabase](https://supabase.com/) and create a new project
   - Enable Email and Google authentication in the Auth settings
   - Create the necessary tables using the provided SQL scripts:
     
     **Profiles Table**
     ```sql
     create table profiles (
       id uuid references auth.users on delete cascade primary key,
       email text unique not null,
       name text,
       avatar_url text,
       updated_at timestamp with time zone
     );
     
     -- Create a secure RLS policy
     alter table profiles enable row level security;
     create policy "Users can view their own profile" on profiles
       for select using (auth.uid() = id);
     create policy "Users can update their own profile" on profiles
       for update using (auth.uid() = id);
     ```

     **Documents Table and Storage Setup**
     - Execute the SQL in the `supabase_documents_setup.sql` file to create the documents table and configure storage

2. **Configure OpenAI API**
   - Get an API key from [OpenAI](https://openai.com/)
   - Update the `apiKey` in `lib/services/openai_service.dart` with your actual API key

3. **Configure your Flutter project**
   - Update the Supabase URL and anon key in `lib/main.dart` with your Supabase project credentials:
     ```dart
     await Supabase.initialize(
       url: 'YOUR_SUPABASE_URL',
       anonKey: 'YOUR_SUPABASE_ANON_KEY',
     );
     ```

4. **Configure Google Sign-In**
   - For Android and iOS, follow the [Supabase documentation](https://supabase.com/docs/guides/auth/social-login/auth-google) to set up Google Sign-In

5. **Install dependencies and run the app**
   ```
   flutter pub get
   flutter run
   ```

## Document Management

The app supports uploading and managing various document types:
- PDF files
- Word documents (.doc, .docx)
- Images (.jpg, .jpeg, .png)

When a document is uploaded:
1. The file is stored in Supabase Storage
2. OpenAI analyzes the file name and type to generate an appropriate tag
3. The file metadata and tag are stored in the documents table
4. Documents are automatically organized by tags in the sidebar

## Architecture

The app follows the MVC (Model-View-Controller) pattern:

- **Models**: Data structures like UserModel and DocumentModel
- **Views**: UI components in the views directory
- **Controllers**: Business logic in the controllers directory

GetX is used for:
- State management with reactive variables
- Navigation without context
- Dependency injection

## Customization

- Add more tags or categories in the OpenAI service prompt
- Customize the UI by updating the neomorphic styling
- Add document search functionality
- Implement document preview for different file types

# Plynt

## Environment Variables for Deployment

This project uses environment variables for configuration. When deploying to Vercel:

1. Set up the following environment variables in your Vercel project settings:
   - `OPENAI_API_KEY`: Your OpenAI API key
   - `SUPABASE_URL`: Your Supabase URL
   - `SUPABASE_ANON_KEY`: Your Supabase anonymous key

2. The `vercel.json` file is configured to automatically use these environment variables during the build process.

## Local Development

For local development:

1. Create a `.env` file in the project root with the following variables:
   ```
   OPENAI_API_KEY=your_api_key_here
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

2. Run the app using:
   ```bash
   flutter run -d chrome
   ```

## Using dart-define for Different Environments

You can also use `--dart-define` to inject environment variables at build time:

```bash
flutter run -d chrome --dart-define=OPENAI_API_KEY=your_api_key_here
```

For production builds:

```bash
flutter build web --release --dart-define=OPENAI_API_KEY=your_api_key_here
```
