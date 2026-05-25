import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken]       = useState(() => localStorage.getItem('token') || null);
  const [member, setMember]     = useState(() => {
    try { return JSON.parse(localStorage.getItem('member')) || null; } catch { return null; }
  });
  const [family, setFamily]     = useState(() => {
    try { return JSON.parse(localStorage.getItem('family')) || null; } catch { return null; }
  });
  const [savedAccounts, setSavedAccounts] = useState(() => {
    try { return JSON.parse(localStorage.getItem('savedAccounts')) || []; } catch { return []; }
  });

  const isLoggedIn = !!token;

  // Persist whenever values change
  useEffect(() => {
    if (token) localStorage.setItem('token', token);
    else       localStorage.removeItem('token');
  }, [token]);

  useEffect(() => {
    if (member) localStorage.setItem('member', JSON.stringify(member));
    else        localStorage.removeItem('member');
  }, [member]);

  useEffect(() => {
    if (family) localStorage.setItem('family', JSON.stringify(family));
    else        localStorage.removeItem('family');
  }, [family]);

  useEffect(() => {
    localStorage.setItem('savedAccounts', JSON.stringify(savedAccounts));
  }, [savedAccounts]);

  // Called after successful login
  const login = (responseData) => {
    const { token: tok, data } = responseData;
    setToken(tok);
    setMember(data?.member || null);
    setFamily(data?.family || null);

    // Save this account to the saved accounts list (for quick switching)
    if (data?.member && data?.family) {
      const account = {
        token: tok,
        member: data.member,
        family: data.family,
        // key = familyId + memberId so each family-member combo is unique
        key: `${data.family._id}_${data.member._id}`,
      };
      setSavedAccounts((prev) => {
        const filtered = prev.filter((a) => a.key !== account.key);
        return [account, ...filtered].slice(0, 10); // keep max 10
      });
    }
  };

  // Switch to a previously saved account
  const switchAccount = (account) => {
    setToken(account.token);
    setMember(account.member);
    setFamily(account.family);
    localStorage.setItem('token', account.token);
  };

  // Remove a saved account
  const removeAccount = (key) => {
    setSavedAccounts((prev) => prev.filter((a) => a.key !== key));
  };

  const logout = () => {
    setToken(null);
    setMember(null);
    setFamily(null);
    localStorage.removeItem('token');
    localStorage.removeItem('member');
    localStorage.removeItem('family');
  };

  return (
    <AuthContext.Provider value={{
      token, member, family,
      savedAccounts, isLoggedIn,
      login, logout, switchAccount, removeAccount,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
