import React, { useState } from 'react';
import { navigate } from 'gatsby';
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';
import awsConfig from '../awsConfig';

const poolData = {
  UserPoolId: awsConfig.Auth.userPoolId,  // Replace with your User Pool ID
  ClientId: awsConfig.Auth.userPoolWebClientId // Replace with your App Client ID
};

const userPool = new CognitoUserPool(poolData);

const LoginPage = () => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(null);
  const [newPassword, setNewPassword] = useState(''); // Track the new password

  const handleLogin = (event) => {
    event.preventDefault();

    const user = new CognitoUser({
      Username: username,
      Pool: userPool,
    });

    const authDetails = new AuthenticationDetails({
      Username: username,
      Password: password,
    });

    user.authenticateUser(authDetails, {
      onSuccess: (result) => {
        console.log('Login successful!', result);
        // Save the session, if necessary (e.g., token storage)
        localStorage.setItem('idToken', result.getIdToken().getJwtToken());

        // Redirect to the home page
        navigate('/');
      },
      onFailure: (err) => {
        console.error('Login failed', err);
        setError('Invalid username or password');
      },
      newPasswordRequired: (userAttributes, requiredAttributes) => {
        // Handle the NewPasswordRequired challenge
        console.log('New password required');
        setError(null); // Clear previous errors

        // Show a UI to prompt the user for the new password
        // You can handle this by showing a modal or a form
        const newPasswordPrompt = prompt('Your password has expired. Please enter a new password:');
        
        if (newPasswordPrompt) {
          setNewPassword(newPasswordPrompt); // Set the new password

          // Complete the password change
          user.completeNewPasswordChallenge(newPasswordPrompt, requiredAttributes, {
            onSuccess: (result) => {
              console.log('Password updated successfully!', result);
              localStorage.setItem('idToken', result.getIdToken().getJwtToken());
              navigate('/');
            },
            onFailure: (err) => {
              console.error('Error updating password', err);
              setError('Failed to change password');
            },
          });
        }
      },
    });
  };

  return (
    <div>
      <h1>Login</h1>
      {error && <div style={{ color: 'red' }}>{error}</div>}
      <form onSubmit={handleLogin}>
        <div>
          <label>
            Username:
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
            />
          </label>
        </div>
        <div>
          <label>
            Password:
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </label>
        </div>
        <button type="submit">Login</button>
      </form>
    </div>
  );
};

export default LoginPage;
