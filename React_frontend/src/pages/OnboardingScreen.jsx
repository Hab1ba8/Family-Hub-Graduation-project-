import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import './OnboardingScreen.css';

const SLIDES = [
  {
    title: 'Welcome to Family Hub',
    subtitle: 'Your seamless solution for managing\nfamily life, together',
    icon: (
      <svg width="80" height="80" viewBox="0 0 24 24" fill="var(--primary)">
        <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z" />
      </svg>
    ),
  },
  {
    title: 'Stay Organized, Together',
    subtitle: 'Manage tasks, chores and schedules with ease.\nEveryone knows their role',
    icon: (
      <svg width="80" height="80" viewBox="0 0 24 24" fill="var(--primary)">
        <path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-9 14l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z" />
      </svg>
    ),
  },
  {
    title: 'Connect & Communicate',
    subtitle: 'Share moments, send messages, and stay\nin sync instantly',
    icon: (
      <svg width="80" height="80" viewBox="0 0 24 24" fill="var(--primary)">
        <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zm-2 12H6v-2h12v2zm0-3H6V9h12v2zm0-3H6V6h12v2z" />
      </svg>
    ),
  },
  {
    title: 'Rewards & Recognition',
    subtitle: 'Earn points for completed tasks and\nredeem exciting rewards',
    icon: (
      <svg width="80" height="80" viewBox="0 0 24 24" fill="var(--primary)">
        <path d="M19 5h-2V3H7v2H5c-1.1 0-2 .9-2 2v1c0 2.55 1.92 4.63 4.39 4.94.63 1.5 1.98 2.63 3.61 2.96V19H7v2h10v-2h-4v-3.1c1.63-.33 2.98-1.46 3.61-2.96C19.08 12.63 21 10.55 21 8V7c0-1.1-.9-2-2-2zM5 8V7h2v3.82C5.84 10.4 5 9.3 5 8zm14 0c0 1.3-.84 2.4-2 2.82V7h2v1z" />
      </svg>
    ),
  },
];

export default function OnboardingScreen() {
  const navigate = useNavigate();
  const [current, setCurrent] = useState(0);
  const [animDir, setAnimDir] = useState('');

  const goTo = (index, dir) => {
    setAnimDir(dir);
    setTimeout(() => {
      setCurrent(index);
      setAnimDir('');
    }, 250);
  };

  const handleNext = () => {
    if (current < SLIDES.length - 1) goTo(current + 1, 'left');
    else navigate('/login');
  };

  const handleSkip = () => navigate('/login');

  const slide = SLIDES[current];

  return (
    <div className="onboard-page">
      {/* Skip */}
      <div className="onboard-topbar">
        <div />
        <button className="onboard-skip" onClick={handleSkip}>Skip</button>
      </div>

      {/* Slide content */}
      <div className={`onboard-slide ${animDir}`}>
        {/* Icon circle */}
        <div className="onboard-icon-circle">
          {slide.icon}
        </div>

        <h2 className="onboard-title">{slide.title}</h2>
        <p className="onboard-subtitle">{slide.subtitle}</p>
      </div>

      {/* Dot indicators */}
      <div className="onboard-indicators">
        {SLIDES.map((_, i) => (
          <button
            key={i}
            className={`onboard-dot ${i === current ? 'active' : ''}`}
            onClick={() => goTo(i, i > current ? 'left' : 'right')}
          />
        ))}
      </div>

      {/* Next / Get Started button */}
      <div className="onboard-footer">
        <button className="btn-primary" onClick={handleNext}>
          {current === SLIDES.length - 1 ? 'Get Started' : 'Next'}
        </button>

        <p className="onboard-login-link">
          Already have an account?{' '}
          <button onClick={() => navigate('/login')}>Log in</button>
        </p>
      </div>
    </div>
  );
}
