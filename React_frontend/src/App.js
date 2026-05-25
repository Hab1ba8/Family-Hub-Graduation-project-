import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';

import SplashScreen    from './pages/SplashScreen';
import OnboardingScreen from './pages/OnboardingScreen';
import LoginScreen     from './pages/LoginScreen';
import SignUpScreen    from './pages/SignUpScreen';

// Placeholder for Home — replace later when Home screen is built
function HomePage() {
  const { member, family, logout } = useAuth();
  return (
    <div style={{
      minHeight: '100vh',
      background: 'var(--background)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: 'Poppins, sans-serif',
      gap: 16,
    }}>
      <div style={{
        fontSize: 48,
        background: 'white',
        borderRadius: '50%',
        width: 80, height: 80,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 4px 20px rgba(0,137,123,0.15)',
      }}>👨‍👩‍👧‍👦</div>
      <h1 style={{ color: '#00352E', fontSize: 22, fontWeight: 700 }}>
        {family?.Title || family?.title || 'Family Hub'}
      </h1>
      <p style={{ color: '#4DB6AC', fontSize: 14 }}>
        Welcome, {member?.username || 'Member'}!
      </p>
      <button
        onClick={logout}
        style={{
          marginTop: 24,
          padding: '12px 32px',
          borderRadius: 12,
          background: 'var(--primary)',
          color: 'white',
          border: 'none',
          fontFamily: 'Poppins, sans-serif',
          fontWeight: 600,
          fontSize: 15,
          cursor: 'pointer',
        }}
      >
        Logout
      </button>
    </div>
  );
}

// Protected route — redirect to /login if not authenticated
function PrivateRoute({ children }) {
  const { isLoggedIn } = useAuth();
  return isLoggedIn ? children : <Navigate to="/login" replace />;
}

function AppRoutes() {
  return (
    <Routes>
      <Route path="/"            element={<Navigate to="/splash" replace />} />
      <Route path="/splash"      element={<SplashScreen />} />
      <Route path="/onboarding"  element={<OnboardingScreen />} />
      <Route path="/login"       element={<LoginScreen />} />
      <Route path="/signup"      element={<SignUpScreen />} />
      <Route path="/home"        element={<PrivateRoute><HomePage /></PrivateRoute>} />
      {/* Catch-all */}
      <Route path="*"            element={<Navigate to="/splash" replace />} />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
}
