import React, { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './SplashScreen.css';

export default function SplashScreen() {
  const navigate   = useNavigate();
  const { isLoggedIn } = useAuth();
  const hasNavigated   = useRef(false);

  useEffect(() => {
    const timer = setTimeout(() => {
      if (hasNavigated.current) return;
      hasNavigated.current = true;
      navigate(isLoggedIn ? '/home' : '/onboarding', { replace: true });
    }, 3000);
    return () => clearTimeout(timer);
  }, [navigate, isLoggedIn]);

  return (
    <div className="splash-page">
      <div className="splash-center">
        {/* Logo */}
        <div className="splash-logo">
          <svg width="56" height="56" viewBox="0 0 24 24" fill="none">
            <path
              d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"
              fill="var(--primary)"
            />
          </svg>
        </div>

        {/* App name */}
        <h1 className="splash-title">Family Hub</h1>
        <p className="splash-subtitle">Connecting Families Together</p>

        {/* Bouncing dots */}
        <div className="splash-dots">
          <span className="dot dot-1" />
          <span className="dot dot-2" />
          <span className="dot dot-3" />
        </div>
      </div>
    </div>
  );
}
