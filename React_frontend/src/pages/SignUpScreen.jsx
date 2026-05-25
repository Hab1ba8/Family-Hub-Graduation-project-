import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../services/api';
import './AuthScreens.css';

const EmailIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
    <path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
  </svg>
);
const PersonIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
  </svg>
);
const HomeIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
    <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
  </svg>
);
const LockIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
    <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
  </svg>
);
const CalendarIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
    <path d="M20 3h-1V1h-2v2H7V1H5v2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 18H4V8h16v13z"/>
  </svg>
);
const EyeIcon = ({ open }) => open ? (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zM12 17c-2.76 0-5-2.24-5-5s2.24-5 5-5 5 2.24 5 5-2.24 5-5 5zm0-8c-1.66 0-3 1.34-3 3s1.34 3 3 3 3-1.34 3-3-1.34-3-3-3z"/>
  </svg>
) : (
  <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
    <path d="M12 7c2.76 0 5 2.24 5 5 0 .65-.13 1.26-.36 1.83l2.92 2.92c1.51-1.26 2.7-2.89 3.43-4.75-1.73-4.39-6-7.5-11-7.5-1.4 0-2.74.25-3.98.7l2.16 2.16C10.74 7.13 11.35 7 12 7zM2 4.27l2.28 2.28.46.46C3.08 8.3 1.78 10.02 1 12c1.73 4.39 6 7.5 11 7.5 1.55 0 3.03-.3 4.38-.84l.42.42L19.73 22 21 20.73 3.27 3 2 4.27zM7.53 9.8l1.55 1.55c-.05.21-.08.43-.08.65 0 1.66 1.34 3 3 3 .22 0 .44-.03.65-.08l1.55 1.55c-.67.33-1.41.53-2.2.53-2.76 0-5-2.24-5-5 0-.79.2-1.53.53-2.2zm4.31-.78l3.15 3.15.02-.16c0-1.66-1.34-3-3-3l-.17.01z"/>
  </svg>
);

export default function SignUpScreen() {
  const navigate = useNavigate();
  const [form, setForm] = useState({
    familyTitle: '',
    mail: '',
    username: '',
    password: '',
    confirmPassword: '',
    birthDate: '',
  });
  const [showPw,        setShowPw]        = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);
  const [error,         setError]         = useState('');
  const [loading,       setLoading]       = useState(false);

  const set = (field) => (e) => setForm({ ...form, [field]: e.target.value });

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!form.familyTitle || !form.mail || !form.username || !form.password || !form.birthDate) {
      setError('Please fill in all fields'); return;
    }
    if (form.password !== form.confirmPassword) {
      setError('Passwords do not match'); return;
    }
    if (form.password.length < 6) {
      setError('Password must be at least 6 characters'); return;
    }

    setLoading(true);
    try {
      await authAPI.signup(form);
      navigate('/login');
    } catch (err) {
      setError(err.response?.data?.message || 'Sign up failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-page" style={{ paddingTop: 32, paddingBottom: 32 }}>
      <div className="auth-card">
        {/* Back */}
        <button className="auth-back-btn" onClick={() => navigate('/login')}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/>
          </svg>
        </button>

        {/* Logo */}
        <div className="auth-logo-circle">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="var(--primary)">
            <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>
          </svg>
        </div>

        <h1 className="auth-heading">Create Your Family</h1>
        <p className="auth-subheading">Start your Family Hub journey</p>

        {error && <div className="error-box">{error}</div>}

        <form onSubmit={handleSubmit} className="auth-form">
          {/* Family Title */}
          <div className="input-wrapper">
            <span className="input-icon"><HomeIcon /></span>
            <input
              className="field-input"
              type="text"
              placeholder="Family title (e.g. Smith Family)"
              value={form.familyTitle}
              onChange={set('familyTitle')}
            />
          </div>

          {/* Email */}
          <div className="input-wrapper">
            <span className="input-icon"><EmailIcon /></span>
            <input
              className="field-input"
              type="email"
              placeholder="Email address"
              value={form.mail}
              onChange={set('mail')}
            />
          </div>

          {/* Username */}
          <div className="input-wrapper">
            <span className="input-icon"><PersonIcon /></span>
            <input
              className="field-input"
              type="text"
              placeholder="Username"
              value={form.username}
              onChange={set('username')}
            />
          </div>

          {/* Birth Date */}
          <div className="input-wrapper">
            <span className="input-icon"><CalendarIcon /></span>
            <input
              className="field-input"
              type="date"
              placeholder="Birth date"
              value={form.birthDate}
              onChange={set('birthDate')}
            />
          </div>

          {/* Password */}
          <div className="input-wrapper">
            <span className="input-icon"><LockIcon /></span>
            <input
              className="field-input"
              type={showPw ? 'text' : 'password'}
              placeholder="Password"
              value={form.password}
              onChange={set('password')}
            />
            <button type="button" className="input-suffix" onClick={() => setShowPw(!showPw)}>
              <EyeIcon open={showPw} />
            </button>
          </div>

          {/* Confirm Password */}
          <div className="input-wrapper">
            <span className="input-icon"><LockIcon /></span>
            <input
              className="field-input"
              type={showConfirmPw ? 'text' : 'password'}
              placeholder="Confirm password"
              value={form.confirmPassword}
              onChange={set('confirmPassword')}
            />
            <button type="button" className="input-suffix" onClick={() => setShowConfirmPw(!showConfirmPw)}>
              <EyeIcon open={showConfirmPw} />
            </button>
          </div>

          <button className="btn-primary" type="submit" disabled={loading}>
            {loading ? 'Creating...' : 'Create Family Account'}
          </button>
        </form>

        <p className="auth-switch-text">
          Already have an account?{' '}
          <button onClick={() => navigate('/login')}>Log in</button>
        </p>
      </div>
    </div>
  );
}
