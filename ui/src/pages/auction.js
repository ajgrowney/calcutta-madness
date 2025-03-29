import React, { useEffect, useState, useRef } from 'react';
import { Card, Carousel, Container, Button, Table, Alert, Form, Spinner } from "react-bootstrap";
import { useLocation, navigate } from "@reach/router";
import { CognitoUserPool, CognitoUser, AuthenticationDetails } from 'amazon-cognito-identity-js';
import awsConfig from '../awsConfig';
import '../styles/bracket.css';
import 'bootstrap/dist/css/bootstrap.min.css';
const API_HOST = awsConfig.APIs.rest;
const WS_ENDPOINT = awsConfig.APIs.websockets;
const poolData = {
  UserPoolId: awsConfig.Auth.userPoolId,  // Replace with your User Pool ID
  ClientId: awsConfig.Auth.userPoolWebClientId // Replace with your App Client ID
};

const userPool = new CognitoUserPool(poolData);
const AdminPanel = ({ user, auctionDetails, isAdmin, auctionId, setCurrentItem }) => {
    const startAuctionReq = async (session, auctionId, setCurrentItem) => {
        const response = await fetch(`${API_HOST}/auctions/${auctionId}/start`, {
            method: 'POST',
            headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }),
            mode: 'cors',
        });
        let data = await response.json();
        return data;
    }
    const nextItemReq = async (session, auctionId) => {
        const response = await fetch(`${API_HOST}/auctions/${auctionId}/next`, {
            method: 'POST', headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }), mode: 'cors',
        });
        let data = await response.json();
        return data;
    }
    const makeReq = (user, auctionId, req, setCurrentItem) => {
        console.log(`Making request for: ${auctionId}`);
        user.getSession((err, session) => {
            if (err || !session.isValid()) {
                console.error('Failed to get session');
            } else {
                req(session, auctionId).then(data => {
                    if (setCurrentItem) {
                        setCurrentItem(data);
                    }
                }).catch(err => {
                    console.error('Failed to make request', err);
                }
                );
            }
        })
    }
    const addTimeReq = async (session, auctionId) => {
        // Add 30 seconds from now
        let newExpiresAt = new Date();
        newExpiresAt.setSeconds(newExpiresAt.getSeconds() + 30);
        const response = await fetch(`${API_HOST}/auctions/${auctionId}/add-time`, {
            method: 'POST', headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }), mode: 'cors',
            body: JSON.stringify({ expiresAt: newExpiresAt.toISOString() })
        });
        let data = await response.json()
        return data;
    }
    return (
        <div>
            <h3>Admin Panel</h3>
            <div>
                <Button onClick={() => makeReq(user, auctionId, startAuctionReq, setCurrentItem)}>Start Auction</Button>
                <Button onClick={() => makeReq(user, auctionId, nextItemReq)}>Next Item</Button>
                <Button onClick={() => makeReq(user, auctionId, addTimeReq)}>Add Time</Button>
            </div>
        </div>
    )
}
const placeBid = (user, auctionId, itemId, bidAmount) => {
    console.log(`Placing bid: ${bidAmount} on item: ${itemId} in auction: ${auctionId}`);
    let res = null
    if (!user) {
        console.error('No user');
        return res;
    }
    user.getSession((err, session) => {
        if (err || !session.isValid()) {
            console.error('Failed to get session');
        } else {
            fetch(`${API_HOST}/auctions/${auctionId}/bid`, {
                method: 'POST',
                headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }),
                mode: 'cors',
                body: JSON.stringify({ itemId, bidAmount})
            }).then(res => res.json()).then(data => {
                console.log(data);
                res = data;
            }).catch(err => {
                console.error('Failed to place bid', err);
            });
    }});
    return res;
}
const BidForm = ({user, auctionDetails, currentItem, expiresAt}) => {
    const [timeLeft, setTimeLeft] = useState(null);
    const [bidAmount, setBidAmount] = useState(0);
    
    useEffect(() => {
        const calculateTimeLeft = (expiresAt) => {
            const difference = Date.parse(expiresAt) - new Date();
            let timeLeft = false;

            if (difference > 0) {
                timeLeft = {
                    hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
                    minutes: Math.floor((difference / 1000 / 60) % 60),
                    seconds: Math.floor((difference / 1000) % 60)
                };
            }

            return timeLeft;
        };

        const timer = setInterval(() => {
            setTimeLeft(calculateTimeLeft(expiresAt));
        }, 1000);

        return () => clearInterval(timer);
    }, [expiresAt]);

    return (
        <Form>
            <div>
                {timeLeft ? (
                    <span>Closing in: {timeLeft.hours}h {timeLeft.minutes}m {timeLeft.seconds}s</span>) : (
                    <span>Closed</span>
                )}
            </div>
            <Form.Group>
            <Form.Control type="number"  placeholder="Enter bid amount"  disabled={!timeLeft}  value={bidAmount}  onChange={(e) => setBidAmount(e.target.value)} />
            </Form.Group>
            <Button onClick={() => placeBid(user, auctionDetails.auctionId, currentItem?.id, Number(bidAmount))} disabled={!timeLeft}>Place Bid</Button>
        </Form>
    );
}

const AuctionCurrentBlock = ({ user, auctionDetails, auctionItems, currentItem }) => {
    if (auctionDetails?.auctionState !== 'LIVE') {
        return (
            <Alert variant="info">The auction has not started yet.</Alert>
        )
    }
    let { id, price, bidder, expiresAt } = currentItem;
    bidder = getUserEmail(bidder, auctionDetails.participants);
    let currentItemInfo = auctionItems.find(item => item.id === id);
    let teamPanel = <h4>No item</h4>;
    if (currentItemInfo) {
        teamPanel = (
            <>{currentItemInfo.name} {currentItemInfo.seed} {currentItemInfo.region} </>
        );
    }

    return (
        <Card style={{ width: '90dvw', 'padding': '1rem', 'textAlign': 'center' }}>
            <Card.Title>On the Block: {teamPanel}</Card.Title>
            <Card.Body>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                    <h6>Current Bid: {price} { bidder || "No bids"}</h6>
                    <BidForm user={user} 
                        auctionDetails={auctionDetails} 
                        currentItem={currentItem} 
                        expiresAt={expiresAt} />
                </div>
            </Card.Body>
        </Card>
    )
}
const bracketOrder = [1, 16, 8, 9, 5, 12, 4, 13, 6, 11, 3, 14, 7, 10, 2, 15];
const AuctionBracket = ({ auctionDetails, auctionItems, auctionHistory }) => {

    const regions = {S: [], W: [], E: [], MW: [] };

    // Separate groups and individual teams
    auctionItems.forEach(item => {
        if (regions[item.region]) {
            if (item.type === "group") {
                regions[item.region] = regions[item.region].concat(item.info);
            } else {
                regions[item.region].push(item);
            }
        }
    });
    // Function to order teams correctly
    const orderByBracket = (teams) => {
        return teams
            .map(team => ({
                ...team,
                seed: parseInt(team.seed, 10) // Convert seed to number for sorting
            }))
            .sort((a, b) => bracketOrder.indexOf(a.seed) - bracketOrder.indexOf(b.seed));
    };
    const userEmails = auctionDetails.participants.reduce((acc, participant) => {
        acc[participant.userId] = participant.email;
        return acc;
    }
    , {});
    
    return (
        <div className="bracket-container">
            <div className="bracket-left">
                <div className="region">
                    <h2>South</h2>
                    {orderByBracket(regions.S).map(item => (
                        <div key={item.name} className="bracket-item">
                            <div className="bracket-auction-item">
                                <span>{item.seed}</span>
                                <span>{item.name}</span>
                                {item.auctioned ? ( <span>${item.price}</span>) : (<span></span>)}
                            </div>
                            {item.auctioned && (
                                <div className="bracket-auction-owner"><span>{userEmails[item.bidder]}</span></div>
                            )}
                        </div>
                    ))}
                </div>
                <div className="region">
                    <h2>West</h2>
                    {orderByBracket(regions.W).map(item => (
                        <div key={item.name} className="bracket-item">
                            <div className="bracket-auction-item">
                                <span>{item.seed}</span>
                                <span>{item.name}</span>
                                {item.auctioned ? ( <span>${item.price}</span>) : (<span></span>)}
                            </div>
                            {item.auctioned && (
                                <div className="bracket-auction-owner"><span>{userEmails[item.bidder]}</span></div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
            
            <div className="bracket-middle"></div>

            <div className="bracket-right">
                <div className="region">
                    <h2>East</h2>
                    {orderByBracket(regions.E).map(item => (
                        <div key={item.name} className="bracket-item">
                            <div className="bracket-auction-item">
                                <span>{item.seed}</span>
                                <span>{item.name}</span>
                                {item.auctioned ? ( <span>${item.price}</span>) : (<span></span>)}
                            </div>
                            {item.auctioned && (
                                <div className="bracket-auction-owner"><span>{userEmails[item.bidder]}</span></div>
                            )}
                        </div>
                    ))}
                </div>
                <div className="region">
                    <h2>Midwest</h2>
                    {orderByBracket(regions.MW).map(item => (
                        <div key={item.name} className="bracket-item">
                            <div className="bracket-auction-item">
                                <span>{item.seed}</span>
                                <span>{item.name}</span>
                                {item.auctioned ? ( <span>${item.price}</span>) : (<span></span>)}
                            </div>
                            {item.auctioned && (
                                <div className="bracket-auction-owner"><span>{userEmails[item.bidder]}</span></div>
                            )}
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
}
const getUserEmail = (userId, participants) => {
    return participants.find(participant => participant.userId === userId)?.email;
}
const AuctionHistory = ({ auctionHistory, auctionDetails }) => {

    // sort auction history by closed_at descending
    auctionHistory.sort((a, b) => new Date(b.closed_at) - new Date(a.closed_at));
    return (
        <Card>
            <Card.Title>Auction History</Card.Title>
            <Card.Body>
                <Table striped bordered hover>
                    <thead>
                        <tr><th>Item</th><th>Winner</th><th>Price</th></tr>
                    </thead>
                    <tbody>
                        {auctionHistory.map((historyItem, index) => (
                            <tr key={index}>
                                <td>{historyItem.name}</td><td>{getUserEmail(historyItem.bidder, auctionDetails.participants)}</td><td>{historyItem.price}</td>
                            </tr>
                        ))}
                    </tbody>
                </Table>
            </Card.Body>
        </Card>

    )
}
const AuctionOverview = ({ auctionDetails, auctionHistory, auctionItems }) => {
    let [index, setIndex] = useState(0);
    const handleSelect = (selectedIndex) => {
        setIndex(selectedIndex);
      };
    if (!auctionHistory || !auctionItems) {
        return <div>Loading Auction Overview...</div>;
    }
    return (
        <Carousel interval={null} activeIndex={index} onSelect={handleSelect} style={{ width: '90vw', height: '50vh', padding: '1rem' }}>
            <Carousel.Item>
                <AuctionBracket auctionDetails={auctionDetails} auctionItems={auctionItems} auctionHistory={auctionHistory} />
            </Carousel.Item>
            <Carousel.Item>
                <AuctionHistory auctionDetails={auctionDetails} auctionHistory={auctionHistory} />
            </Carousel.Item>
        </Carousel>
    )
}
const fetchAuctionDetails = async (session, auctionId) => {
    console.log(`Fetching auction details for auction: ${auctionId}`);
    const response = await fetch(`${API_HOST}/auctions/${auctionId}`, {
        method: 'GET',
        headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }),
        mode: 'cors',
    });
    let data = await response.json();
    return data;
}
const fetchAuctionItems = async (session, auctionId) => {
    console.log(`Fetching auction items for auction: ${auctionId}`);
    const response = await fetch(`${API_HOST}/auctions/${auctionId}/items`, {
        method: 'GET', headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }), mode: 'cors',
    });
    let data = await response.json();
    return data;
}
const fetchAuctionHistory = async (session, auctionId) => {
    console.log(`Fetching auction history for auction: ${auctionId}`);
    const response = await fetch(`${API_HOST}/auctions/${auctionId}/history`, {
        method: 'GET', headers: new Headers({ 'Authorization': `Bearer ${session.getIdToken().getJwtToken()}`, 'Content-Type': 'application/json' }), mode: 'cors',
    });
    let data = await response.json();
    return data;
}
const AuctionRoom = () => {
    const location = useLocation();
    const queryParams = new URLSearchParams(location.search);
    const auctionId = queryParams.get("id");
    console.log('AUCTION: ', auctionId);

    const [auctionDetails, setAuctionDetails] = useState(null);
    const [loadingAuctionDetails, setLoadingAuctionDetails] = useState(true);
    const [currentItem, setCurrentItem] = useState(null);
    const [auctionHistory, setAuctionHistory] = useState([]);
    const [loadingAuctionHistory, setLoadingAuctionHistory] = useState(false);
    const [auctionItems, setAuctionItems] = useState([]);
    const [loadingAuctionItems, setLoadingAuctionItems] = useState(false);
    const [user, setUser] = useState(null);
    const [userAttributes, setUserAttributes] = useState(null);
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const wsRef = useRef(null);
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
                setUserAttributes(session.getIdToken().payload);
                setIsAuthenticated(true);
                Promise.all([
                    fetchAuctionDetails(session, auctionId),
                    fetchAuctionItems(session, auctionId),
                    fetchAuctionHistory(session, auctionId)
                ]).then(([auctionDetailsResponse, auctionItemsResponse, auctionHistoryResponse]) => {;
                    setAuctionDetails(auctionDetailsResponse);
                    setCurrentItem(auctionDetailsResponse.currentItem);
                    setAuctionItems(auctionItemsResponse);
                    setAuctionHistory(auctionHistoryResponse);
                    setLoadingAuctionDetails(false);
                    setLoadingAuctionItems(false);
                    setLoadingAuctionHistory(false);
                }).catch(err => {
                    console.error('Failed to fetch auction details', err);
                    setIsAuthenticated(false);
                    navigate('/login');
                });
            }
          });
        } else {
          setIsAuthenticated(false);
          navigate('/login');
        }
      }, []);
      useEffect(() => {
        if (isAuthenticated) {
            const ws = new WebSocket(WS_ENDPOINT);
            wsRef.current = ws;

            ws.onopen = () => {
                console.log('WebSocket connection opened');
            };

            ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                console.log('WebSocket message received:', message);
                if (message.type === 'CURRENT_ITEM_UPDATE') {
                    console.log('Updating current item:', message.data);
                    setCurrentItem(message.data);
                } else if (message.type === 'AUCTION_ITEM_FINISHED') {
                    console.log('Auction item finished:', message.data);
                    // Update the auction item by id
                    setAuctionItems(prevItems => {
                        return prevItems.map(item => {
                            console.log(item.name, item.id, message.data.id);
                            if (item.id === message.data.id) {
                                console.log("GOT A HIT: ", item.name)
                                return message.data;
                            }
                            return item;
                        });
                    });
                    // Update the auction history
                    setAuctionHistory(prevHistory => [...prevHistory, message.data]);
                }
            };

            ws.onclose = () => {
                console.log('WebSocket connection closed');
                // Try to reconnect
                wsRef.current = new WebSocket(WS_ENDPOINT);
            };

            ws.onerror = (error) => {
                console.error('WebSocket error:', error);
                console.error(JSON.stringify(error))
            };

            return () => {
                if (wsRef.current) {
                    wsRef.current.close();
                }
            };
        }
    }, [isAuthenticated]);
    console.log(auctionId, isAuthenticated, loadingAuctionDetails);
    if (!isAuthenticated || loadingAuctionDetails) {
        return <div>Loading...</div>;  // Show loading state while checking authentication
    }
    // Find the auctionDetails.participant object with role=admin
    const isAdmin = (auctionDetails?.participants.find(participant => participant.role === 'admin'))?.email === userAttributes.email;
    return (
        <Container style={styleFullScreen}>
          <h2>{auctionDetails?.name || "Auction Room"}</h2>
          <h5>Welcome, {userAttributes?.email || "Guest"}</h5>
          
          {isAdmin && (
            <AdminPanel user={user} auctionDetails={auctionDetails} auctionId={auctionId} setCurrentItem={setCurrentItem} />
          )}
          
          <AuctionCurrentBlock user={user}
            auctionDetails={auctionDetails} 
            currentItem={currentItem}
            auctionItems={auctionItems}
          />
                    
          <AuctionOverview auctionDetails={auctionDetails} auctionHistory={auctionHistory} auctionItems={auctionItems} />
    
        </Container>
    );
};
    
export default AuctionRoom;

const styleFullScreen = {
    height: "100vh",
    width: "100vw",
    display: "flex",
    flexDirection: "column",
    justifyContent: "center",
    alignItems: "center"
};