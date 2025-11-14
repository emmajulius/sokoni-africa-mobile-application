# 📚 Sokoni Africa API Documentation

**Base URL:** `https://sokoni-africa-app.onrender.com` (Production)  
**Local Development:** `http://localhost:8000`  
**API Version:** 1.0.0

---

## Table of Contents

1. [Authentication Endpoints](#authentication-endpoints)
2. [User Management Endpoints](#user-management-endpoints)
3. [Product Endpoints](#product-endpoints)
4. [Order Endpoints](#order-endpoints)
5. [Cart Endpoints](#cart-endpoints)
6. [Wallet & Payment Endpoints](#wallet--payment-endpoints)
7. [Messaging Endpoints](#messaging-endpoints)
8. [Notification Endpoints](#notification-endpoints)
9. [Story Endpoints](#story-endpoints)
10. [File Upload Endpoints](#file-upload-endpoints)
11. [Auction Endpoints](#auction-endpoints)
12. [KYC Endpoints](#kyc-endpoints)

---

## Authentication Endpoints

### 1. Register User

**POST** `/api/auth/register`

Register a new user account.

**Request Body:**
```json
{
  "username": "john_doe",
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "+255712345678",
  "password": "SecurePass123!",
  "user_type": "client",
  "gender": "male"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "username": "john_doe",
    "email": "john@example.com",
    "full_name": "John Doe",
    "user_type": "client"
  }
}
```

**cURL Example:**
```bash
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "full_name": "John Doe",
    "email": "john@example.com",
    "phone": "+255712345678",
    "password": "SecurePass123!",
    "user_type": "client"
  }'
```

---

### 2. Login User

**POST** `/api/auth/login`

Authenticate user and receive access token.

**Request Body:**
```json
{
  "username": "john_doe",
  "password": "SecurePass123!"
}
```

**Alternative (Email/Phone):**
```json
{
  "email": "john@example.com",
  "password": "SecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "username": "john_doe",
    "email": "john@example.com",
    "user_type": "client"
  }
}
```

**cURL Example:**
```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "SecurePass123!"
  }'
```

---

### 3. Send OTP

**POST** `/api/auth/send-otp`

Send OTP code to phone number for verification.

**Request Body:**
```json
{
  "phone": "+255712345678"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "OTP sent successfully",
  "phone": "+255712345678"
}
```

---

### 4. Verify OTP

**POST** `/api/auth/verify-otp`

Verify OTP code and receive access token.

**Request Body:**
```json
{
  "phone": "+255712345678",
  "code": "123456"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "phone": "+255712345678"
  }
}
```

---

### 5. Register with Phone (After OTP Verification)

**POST** `/api/auth/register-with-phone`

Complete registration after OTP verification.

**Request Body:**
```json
{
  "phone": "+255712345678",
  "username": "john_doe",
  "full_name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123!",
  "user_type": "client",
  "gender": "male"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "username": "john_doe",
    "phone": "+255712345678"
  }
}
```

---

### 6. Google Sign-In

**POST** `/api/auth/login`

Login using Google ID token.

**Request Body:**
```json
{
  "google_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6Ij..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": 42,
    "email": "john@gmail.com",
    "full_name": "John Doe"
  }
}
```

---

### 7. Forgot Password (Phone)

**POST** `/api/auth/forgot-password`

Send OTP to reset password via phone.

**Request Body:**
```json
{
  "phone": "+255712345678"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "OTP sent to phone"
}
```

---

### 8. Forgot Password (Email)

**POST** `/api/auth/forgot-password-email`

Send password reset link via email.

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Password reset email sent"
}
```

---

### 9. Reset Password

**POST** `/api/auth/reset-password`

Reset password after OTP/email verification.

**Request Body:**
```json
{
  "phone": "+255712345678",
  "code": "123456",
  "new_password": "NewSecurePass123!"
}
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Password reset successfully"
}
```

---

### 10. Login as Guest

**POST** `/api/auth/guest?user_type=client`

Create a guest session (no authentication required).

**Query Parameters:**
- `user_type`: `client` | `supplier` | `retailer` (default: `client`)

**Response (200 OK):**
```json
{
  "access_token": "guest_token_...",
  "token_type": "bearer",
  "user": {
    "id": null,
    "user_type": "client",
    "is_guest": true
  }
}
```

---

### 11. Get Current User

**GET** `/api/auth/me`

Get current authenticated user information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 42,
  "username": "john_doe",
  "email": "john@example.com",
  "full_name": "John Doe",
  "phone": "+255712345678",
  "user_type": "client",
  "profile_image": "https://...",
  "created_at": "2025-11-14T10:00:00Z"
}
```

---

## User Management Endpoints

### 12. Get Current User Profile

**GET** `/api/users/me`

Get authenticated user's profile.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 42,
  "username": "john_doe",
  "full_name": "John Doe",
  "email": "john@example.com",
  "phone": "+255712345678",
  "user_type": "client",
  "gender": "male",
  "profile_image": "https://...",
  "location_address": "Dar es Salaam, Tanzania",
  "latitude": -6.7924,
  "longitude": 39.2083,
  "created_at": "2025-11-14T10:00:00Z"
}
```

---

### 13. Update User Profile

**PUT** `/api/users/me`

Update authenticated user's profile.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "username": "john_updated",
  "full_name": "John Updated",
  "email": "john.updated@example.com",
  "phone": "+255712345679",
  "gender": "male",
  "profile_image": "https://...",
  "location_address": "Nairobi, Kenya",
  "latitude": -1.2921,
  "longitude": 36.8219
}
```

**Response (200 OK):**
```json
{
  "id": 42,
  "username": "john_updated",
  "full_name": "John Updated",
  "email": "john.updated@example.com",
  "user_type": "client",
  "updated_at": "2025-11-14T12:00:00Z"
}
```

---

### 14. Get User by ID

**GET** `/api/users/{user_id}`

Get public user profile by ID.

**Response (200 OK):**
```json
{
  "id": 42,
  "username": "john_doe",
  "full_name": "John Doe",
  "profile_image": "https://...",
  "user_type": "client",
  "created_at": "2025-11-14T10:00:00Z"
}
```

---

### 15. Follow User

**POST** `/api/users/{user_id}/follow`

Follow another user.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (201 Created):**
```json
{
  "status": "success",
  "message": "You are now following john_doe"
}
```

---

### 16. Unfollow User

**DELETE** `/api/users/{user_id}/follow`

Unfollow a user.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "You unfollowed john_doe"
}
```

---

### 17. Get User Followers

**GET** `/api/users/{user_id}/followers`

Get list of user's followers.

**Response (200 OK):**
```json
[
  {
    "id": 10,
    "username": "follower1",
    "full_name": "Follower One",
    "profile_image": "https://..."
  }
]
```

---

### 18. Get User Following

**GET** `/api/users/{user_id}/following`

Get list of users that this user follows.

**Response (200 OK):**
```json
[
  {
    "id": 20,
    "username": "following1",
    "full_name": "Following One",
    "profile_image": "https://..."
  }
]
```

---

## Product Endpoints

### 19. Get Products

**GET** `/api/products`

Get list of products with optional filters.

**Query Parameters:**
- `skip`: Number of items to skip (default: 0)
- `limit`: Number of items to return (default: 20)
- `category`: Filter by category slug
- `search`: Search query string
- `seller_id`: Filter by seller ID
- `latitude`: User latitude for distance sorting
- `longitude`: User longitude for distance sorting
- `status`: Filter by status (`active`, `sold`, `pending`)

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "title": "Organic Coffee Beans",
    "description": "Washed Arabica, 1kg bag",
    "price": 19.99,
    "currency": "USD",
    "category": "food",
    "seller_id": 42,
    "seller_username": "coffee_seller",
    "seller_profile_image": "https://...",
    "images": ["https://..."],
    "tags": ["coffee", "organic"],
    "is_auction": false,
    "created_at": "2025-11-14T10:00:00Z",
    "likes": 15,
    "comments": 3,
    "rating": 4.5
  }
]
```

**cURL Example:**
```bash
curl -X GET "http://localhost:8000/api/products?limit=10&category=electronics" \
  -H "Content-Type: application/json"
```

---

### 20. Get Product by ID

**GET** `/api/products/{product_id}`

Get detailed product information.

**Response (200 OK):**
```json
{
  "id": 1,
  "title": "Organic Coffee Beans",
  "description": "Washed Arabica, 1kg bag from Tanzania",
  "price": 19.99,
  "currency": "USD",
  "category": "food",
  "seller_id": 42,
  "seller_username": "coffee_seller",
  "seller_profile_image": "https://...",
  "seller_location": "Dar es Salaam, Tanzania",
  "images": ["https://..."],
  "tags": ["coffee", "organic", "beans"],
  "is_liked": false,
  "likes": 15,
  "comments": 3,
  "rating": 4.5,
  "stock_quantity": 50,
  "is_auction": false,
  "created_at": "2025-11-14T10:00:00Z"
}
```

---

### 21. Create Product

**POST** `/api/products`

Create a new product listing (suppliers/retailers only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "title": "Organic Coffee Beans",
  "description": "Washed Arabica, 1kg bag",
  "price": 19.99,
  "currency": "USD",
  "category": "food",
  "images": ["https://res.cloudinary.com/.../coffee.jpg"],
  "tags": ["coffee", "organic"],
  "stock_quantity": 50,
  "unit_type": "kg",
  "is_winga_enabled": false,
  "has_warranty": false,
  "is_private": false,
  "is_adult_content": false
}
```

**Response (201 Created):**
```json
{
  "id": 123,
  "title": "Organic Coffee Beans",
  "description": "Washed Arabica, 1kg bag",
  "price": 19.99,
  "currency": "USD",
  "category": "food",
  "seller_id": 42,
  "images": ["https://..."],
  "status": "active",
  "created_at": "2025-11-14T12:00:00Z"
}
```

---

### 22. Update Product

**PUT** `/api/products/{product_id}`

Update product (owner only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "title": "Updated Product Title",
  "price": 24.99,
  "description": "Updated description"
}
```

**Response (200 OK):**
```json
{
  "id": 123,
  "title": "Updated Product Title",
  "price": 24.99,
  "updated_at": "2025-11-14T13:00:00Z"
}
```

---

### 23. Delete Product

**DELETE** `/api/products/{product_id}`

Delete product (owner only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (204 No Content)**

---

### 24. Like Product

**POST** `/api/products/{product_id}/like`

Like a product.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Product liked",
  "likes": 16
}
```

---

### 25. Unlike Product

**DELETE** `/api/products/{product_id}/like`

Unlike a product.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Product unliked",
  "likes": 15
}
```

---

### 26. Get Product Comments

**GET** `/api/products/{product_id}/comments`

Get comments for a product.

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "product_id": 123,
    "user_id": 42,
    "username": "john_doe",
    "comment": "Great product!",
    "created_at": "2025-11-14T14:00:00Z"
  }
]
```

---

### 27. Add Product Comment

**POST** `/api/products/{product_id}/comments`

Add a comment to a product.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "comment": "Great product! Highly recommended."
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "product_id": 123,
  "user_id": 42,
  "username": "john_doe",
  "comment": "Great product! Highly recommended.",
  "created_at": "2025-11-14T14:00:00Z"
}
```

---

### 28. Rate Product

**POST** `/api/products/{product_id}/rating`

Rate a product (1-5 stars).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "rating": 5
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "product_id": 123,
  "user_id": 42,
  "rating": 5,
  "created_at": "2025-11-14T14:00:00Z"
}
```

---

## Order Endpoints

### 29. Get User Orders

**GET** `/api/orders`

Get authenticated user's purchase orders.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return
- `status`: Filter by order status

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "order_number": "ORD-2025-001",
    "status": "pending",
    "total_amount": 99.99,
    "currency": "USD",
    "items": [
      {
        "product_id": 123,
        "product_title": "Organic Coffee Beans",
        "quantity": 2,
        "price": 19.99,
        "subtotal": 39.98
      }
    ],
    "shipping_address": "Dar es Salaam, Tanzania",
    "created_at": "2025-11-14T15:00:00Z"
  }
]
```

---

### 30. Get Seller Orders

**GET** `/api/orders/sales`

Get orders for seller's products (suppliers/retailers only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "order_number": "ORD-2025-001",
    "status": "pending",
    "buyer_id": 10,
    "buyer_username": "buyer1",
    "total_amount": 99.99,
    "items": [...],
    "created_at": "2025-11-14T15:00:00Z"
  }
]
```

---

### 31. Get Order by ID

**GET** `/api/orders/{order_id}`

Get detailed order information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "order_number": "ORD-2025-001",
  "status": "pending",
  "total_amount": 99.99,
  "shipping_fee": 5.00,
  "items": [...],
  "shipping_address": "Dar es Salaam, Tanzania",
  "created_at": "2025-11-14T15:00:00Z"
}
```

---

### 32. Create Order

**POST** `/api/orders`

Create order from cart items.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "cart_items": [
    {
      "product_id": 123,
      "quantity": 2
    }
  ],
  "shipping_address": "Dar es Salaam, Tanzania",
  "latitude": -6.7924,
  "longitude": 39.2083,
  "payment_method": "wallet"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "order_number": "ORD-2025-001",
  "status": "pending",
  "total_amount": 99.99,
  "items": [...],
  "created_at": "2025-11-14T15:00:00Z"
}
```

---

### 33. Update Order Status

**PUT** `/api/orders/{order_id}/status`

Update order status (seller only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "status": "shipped"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "status": "shipped",
  "updated_at": "2025-11-14T16:00:00Z"
}
```

---

### 34. Confirm Delivery

**POST** `/api/orders/{order_id}/confirm-delivery`

Confirm order delivery (buyer only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "status": "completed",
  "message": "Delivery confirmed. Payment released to seller."
}
```

---

### 35. Get Shipping Estimate

**GET** `/api/orders/shipping/estimate`

Get shipping fee estimate.

**Query Parameters:**
- `seller_latitude`: Seller latitude
- `seller_longitude`: Seller longitude
- `buyer_latitude`: Buyer latitude
- `buyer_longitude`: Buyer longitude

**Response (200 OK):**
```json
{
  "distance_km": 15.5,
  "shipping_fee": 5.00,
  "currency": "SOK"
}
```

---

## Cart Endpoints

### 36. Get Cart Items

**GET** `/api/cart`

Get authenticated user's cart items.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "product_id": 123,
    "product": {
      "id": 123,
      "title": "Organic Coffee Beans",
      "price": 19.99
    },
    "quantity": 2,
    "created_at": "2025-11-14T14:00:00Z"
  }
]
```

---

### 37. Add to Cart

**POST** `/api/cart`

Add product to cart.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "product_id": 123,
  "quantity": 2
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "product_id": 123,
  "quantity": 2,
  "created_at": "2025-11-14T14:00:00Z"
}
```

---

### 38. Update Cart Item

**PUT** `/api/cart/{item_id}`

Update cart item quantity.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "quantity": 3
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "quantity": 3,
  "updated_at": "2025-11-14T15:00:00Z"
}
```

---

### 39. Remove from Cart

**DELETE** `/api/cart/{item_id}`

Remove item from cart.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (204 No Content)**

---

### 40. Clear Cart

**DELETE** `/api/cart`

Clear all cart items.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (204 No Content)**

---

## Wallet & Payment Endpoints

### 41. Get Wallet Balance

**GET** `/api/wallet/balance`

Get authenticated user's wallet balance.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "balance": 1000.50,
  "available_balance": 950.00,
  "pending_balance": 50.50,
  "currency": "SOK",
  "total_earned": 5000.00,
  "total_spent": 3999.50
}
```

---

### 42. Get Wallet Transactions

**GET** `/api/wallet/transactions`

Get wallet transaction history.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return
- `transaction_type`: Filter by type (`topup`, `cashout`, `purchase`, `earned`, `refund`, `fee`)
- `status`: Filter by status (`pending`, `completed`, `failed`)

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "transaction_type": "topup",
    "amount": 1000.00,
    "currency": "SOK",
    "status": "completed",
    "description": "Wallet top-up",
    "created_at": "2025-11-14T10:00:00Z"
  }
]
```

---

### 43. Initialize Wallet Top-Up

**POST** `/api/wallet/topup/initialize`

Initialize wallet top-up payment.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "amount": 25000,
  "currency": "TZS",
  "payment_method": "card",
  "phone_number": "+255712345678",
  "email": "john@example.com",
  "full_name": "John Doe"
}
```

**Response (200 OK):**
```json
{
  "transaction_id": 123,
  "payment_url": "https://checkout.flutterwave.com/...",
  "status": "pending"
}
```

---

### 44. Verify Top-Up

**POST** `/api/wallet/topup/verify/{transaction_id}`

Verify top-up transaction status.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "transaction_id": 123,
  "status": "completed",
  "amount": 1000.00,
  "currency": "SOK"
}
```

---

### 45. Initiate Cashout

**POST** `/api/wallet/cashout`

Initiate wallet cashout.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "sokocoin_amount": 500.00,
  "payout_method": "bank",
  "payout_account": "1234567890",
  "currency": "TZS",
  "full_name": "John Doe",
  "bank_name": "CRDB Bank",
  "account_name": "John Doe"
}
```

**Response (200 OK):**
```json
{
  "transaction_id": 124,
  "status": "pending",
  "amount": 125000.00,
  "currency": "TZS"
}
```

---

### 46. Get Banks List

**GET** `/api/wallet/banks/{country}`

Get list of banks for a country.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "CRDB Bank",
    "code": "CRDB"
  },
  {
    "id": 2,
    "name": "NMB Bank",
    "code": "NMB"
  }
]
```

---

## Messaging Endpoints

### 47. Get Conversations

**GET** `/api/messages/conversations`

Get all conversations for authenticated user.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "other_user": {
      "id": 20,
      "username": "seller1",
      "profile_image": "https://..."
    },
    "last_message": {
      "content": "Hello!",
      "created_at": "2025-11-14T16:00:00Z"
    },
    "unread_count": 2
  }
]
```

---

### 48. Get Conversation Messages

**GET** `/api/messages/conversations/{conversation_id}/messages`

Get messages in a conversation.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "sender_id": 42,
    "receiver_id": 20,
    "content": "Hello!",
    "created_at": "2025-11-14T16:00:00Z"
  }
]
```

---

### 49. Send Message

**POST** `/api/messages/messages`

Send a message to another user.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "receiver_id": 20,
  "content": "Hello! Is this product still available?"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "sender_id": 42,
  "receiver_id": 20,
  "content": "Hello! Is this product still available?",
  "created_at": "2025-11-14T16:00:00Z"
}
```

---

### 50. Get Conversation with User

**GET** `/api/messages/conversations/with/{user_id}`

Get or create conversation with specific user.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "user1_id": 42,
  "user2_id": 20,
  "created_at": "2025-11-14T15:00:00Z"
}
```

---

## Notification Endpoints

### 51. Get Notifications

**GET** `/api/notifications`

Get user notifications.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return
- `unread_only`: Filter unread only (true/false)

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "title": "New Order",
    "body": "You have a new order",
    "type": "order",
    "is_read": false,
    "created_at": "2025-11-14T17:00:00Z"
  }
]
```

---

### 52. Get Unread Count

**GET** `/api/notifications/unread-count`

Get count of unread notifications.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "unread_count": 5
}
```

---

### 53. Mark Notification as Read

**PUT** `/api/notifications/{notification_id}/read`

Mark notification as read.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "is_read": true
}
```

---

### 54. Mark All as Read

**PUT** `/api/notifications/read-all`

Mark all notifications as read.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "updated_count": 5
}
```

---

### 55. Delete Notification

**DELETE** `/api/notifications/{notification_id}`

Delete a notification.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (204 No Content)**

---

### 56. Delete All Notifications

**DELETE** `/api/notifications`

Delete all notifications.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "success",
  "deleted_count": 10
}
```

---

## Story Endpoints

### 57. Get Active Stories

**GET** `/api/stories`

Get all active stories (24-hour expiring).

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "user_id": 42,
    "username": "john_doe",
    "media_url": "https://...",
    "media_type": "image",
    "views_count": 15,
    "expires_at": "2025-11-15T10:00:00Z",
    "created_at": "2025-11-14T10:00:00Z"
  }
]
```

---

### 58. Get User Stories

**GET** `/api/stories/user/{user_id}`

Get stories by specific user.

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "media_url": "https://...",
    "media_type": "image",
    "views_count": 15,
    "expires_at": "2025-11-15T10:00:00Z"
  }
]
```

---

### 59. Create Story

**POST** `/api/stories`

Create a new story.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "media_url": "https://res.cloudinary.com/.../story.jpg",
  "media_type": "image"
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "user_id": 42,
  "media_url": "https://...",
  "media_type": "image",
  "expires_at": "2025-11-15T10:00:00Z",
  "created_at": "2025-11-14T10:00:00Z"
}
```

---

### 60. View Story

**POST** `/api/stories/{story_id}/view`

Increment story view count.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "id": 1,
  "views_count": 16
}
```

---

### 61. Delete Story

**DELETE** `/api/stories/{story_id}`

Delete a story (owner only).

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (204 No Content)**

---

## File Upload Endpoints

### 62. Upload Single File

**POST** `/api/uploads/upload`

Upload a single file.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: File to upload

**Response (201 Created):**
```json
{
  "url": "https://sokoni-africa-app.onrender.com/api/uploads/products/filename.jpg",
  "filename": "filename.jpg",
  "size": 123456
}
```

---

### 63. Upload Multiple Files

**POST** `/api/uploads/upload-multiple`

Upload multiple files.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `files`: Multiple files

**Response (201 Created):**
```json
{
  "urls": [
    "https://sokoni-africa-app.onrender.com/api/uploads/products/file1.jpg",
    "https://sokoni-africa-app.onrender.com/api/uploads/products/file2.jpg"
  ]
}
```

---

### 64. Upload Story Media

**POST** `/api/uploads/upload-story-media`

Upload image or video for story.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: Image or video file

**Response (201 Created):**
```json
{
  "url": "https://...",
  "media_type": "image",
  "thumbnail_url": "https://..." // for videos
}
```

---

### 65. Get Uploaded File

**GET** `/api/uploads/products/{filename}`

Get uploaded file by filename.

**Response:** File content (image/video)

---

## Auction Endpoints

### 66. Get Active Auctions

**GET** `/api/auctions/active`

Get all active auctions.

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return

**Response (200 OK):**
```json
[
  {
    "product_id": 123,
    "product": {
      "id": 123,
      "title": "Vintage Camera",
      "images": ["https://..."]
    },
    "starting_price": 90.00,
    "current_bid": 125.00,
    "bid_count": 5,
    "ends_at": "2025-11-14T20:00:00Z",
    "status": "active"
  }
]
```

---

### 67. Get Auction Details

**GET** `/api/auctions/{product_id}`

Get detailed auction information.

**Response (200 OK):**
```json
{
  "product_id": 123,
  "starting_price": 90.00,
  "current_bid": 125.00,
  "bid_increment": 5.00,
  "bid_count": 5,
  "ends_at": "2025-11-14T20:00:00Z",
  "status": "active",
  "time_remaining_seconds": 3600
}
```

---

### 68. Get Auction Bids

**GET** `/api/auctions/{product_id}/bids`

Get all bids for an auction.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `skip`: Number of items to skip
- `limit`: Number of items to return

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "user_id": 42,
    "username": "john_doe",
    "bid_amount": 125.00,
    "created_at": "2025-11-14T18:00:00Z"
  }
]
```

---

### 69. Place Bid

**POST** `/api/auctions/{product_id}/bid`

Place a bid on an auction.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "bid_amount": 130.00
}
```

**Response (200 OK):**
```json
{
  "id": 2,
  "product_id": 123,
  "user_id": 42,
  "bid_amount": 130.00,
  "is_winning": true,
  "created_at": "2025-11-14T19:00:00Z"
}
```

---

### 70. Complete Auction Payment

**POST** `/api/auctions/{product_id}/complete-payment`

Complete payment for won auction.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `include_shipping`: Include shipping fee (true/false)

**Response (200 OK):**
```json
{
  "status": "success",
  "order_id": 1,
  "total_amount": 130.00
}
```

---

## KYC Endpoints

### 71. Upload KYC Document

**POST** `/api/kyc/upload`

Upload KYC verification document.

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `file`: Document file (ID, passport, etc.)
- `document_type`: Type of document

**Response (201 Created):**
```json
{
  "id": 1,
  "document_type": "national_id",
  "status": "pending",
  "uploaded_at": "2025-11-14T20:00:00Z"
}
```

---

### 72. Get KYC Status

**GET** `/api/kyc/status`

Get KYC verification status.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
{
  "status": "pending",
  "documents_count": 1,
  "verified_at": null
}
```

---

### 73. Get KYC Documents

**GET** `/api/kyc/documents`

Get all uploaded KYC documents.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "document_type": "national_id",
    "status": "pending",
    "uploaded_at": "2025-11-14T20:00:00Z"
  }
]
```

---

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "detail": "Invalid request data"
}
```

### 401 Unauthorized
```json
{
  "detail": "Not authenticated"
}
```

### 403 Forbidden
```json
{
  "detail": "Not enough permissions"
}
```

### 404 Not Found
```json
{
  "detail": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "detail": "Internal server error"
}
```

---

## Authentication

Most endpoints require authentication using JWT Bearer tokens:

```
Authorization: Bearer <access_token>
```

Tokens are obtained from:
- `/api/auth/login` - Username/password login
- `/api/auth/register` - User registration
- `/api/auth/verify-otp` - OTP verification
- `/api/auth/guest` - Guest session

Tokens expire after 30 minutes (configurable). Use refresh token endpoint to obtain new access tokens.

---

## Rate Limiting

API requests are rate-limited to prevent abuse:
- **Authentication endpoints**: 5 requests per minute
- **Other endpoints**: 100 requests per minute

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1636905600
```

---

## API Versioning

Current API version: **v1.0.0**

All endpoints are prefixed with `/api/`. Future versions will use `/api/v2/`, etc.

---

## Interactive API Documentation

- **Swagger UI**: `https://sokoni-africa-app.onrender.com/docs`
- **ReDoc**: `https://sokoni-africa-app.onrender.com/redoc`

---

_Last Updated: November 2025_

