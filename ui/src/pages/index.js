import React, { useEffect, useState } from 'react';
import { Table, Button } from 'react-bootstrap';
import { navigate } from 'gatsby';
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';
import awsConfig from '../awsConfig';
import 'bootstrap/dist/css/bootstrap.min.css';
const API_HOST = awsConfig.APIs.rest;
const poolData = {
  UserPoolId: awsConfig.Auth.userPoolId,  // Replace with your User Pool ID
  ClientId: awsConfig.Auth.userPoolWebClientId // Replace with your App Client ID
};

const userPool = new CognitoUserPool(poolData);

const UserAuctions = ({ currentUser }) => {
  const [auctions, setAuctions] = useState([]);

  useEffect(() => {
    const fetchAuctions = async (session) => {
      const response = await fetch(`${API_HOST}/user-auctions`, {
        method: 'GET',
        headers: new Headers({
          'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`,
            'Content-Type': 'application/json',
        }),
        mode: 'cors',
      });
      let data = await response.json();
      setAuctions(data);
    };

    if (currentUser) {
      currentUser.getSession((err, session) => {
        if (err || !session.isValid()) {
          navigate('/login');
        } else {
          fetchAuctions(session);
        }
      });
    } else {
      navigate('/login');
    }
  }, [currentUser]);

  return (
    <div>
      <h1>Your Auctions</h1>
      <Table striped bordered hover>
        <thead><tr>
            <th>Name</th>
            <th>Status</th>
            <th>Actions</th>
        </tr></thead>
        <tbody>
          {auctions.map((auction, index) => (
            <tr key={auction.auctionId}>
              <td>{auction.name}</td>
              <td>{auction.auctionState}</td>
              <td>
                <Button variant="primary"
                  onClick={() => navigate(`/auction/?id=${auction.auctionId}`)}
                >
                  Join
                </Button>
              </td>
            </tr>
          ))}
        </tbody>
      </Table>
    </div>
  );
}

const IndexPage = () => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Check if the user is authenticated on page load
    const currentUser = userPool.getCurrentUser();
    if (currentUser) {
      currentUser.getSession((err, session) => {
        if (err || !session.isValid()) {
          setIsAuthenticated(false);
          navigate('/login');
        } else {
          setUser(currentUser);
          setIsAuthenticated(true);
        }
      });
    } else {
      setIsAuthenticated(false);
      navigate('/login');
    }
  }, []);

  if (!isAuthenticated) {
    return <div>Loading...</div>;  // Show loading state while checking authentication
  }

  return (
    <div>
      <h1>Welcome to the Home Page!</h1>
      <UserAuctions currentUser={user} />
    </div>
  );
};

export default IndexPage;
