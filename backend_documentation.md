# Shaaka Backend Architecture & Database Design Documentation

This document is a comprehensive guide to the backend architecture and database design of the Shaaka project. It is structured to help you understand the core concepts, technical decisions, and data flow to confidently explain the project in an interview setting.

---

## 1. High-Level Backend Architecture

The backend of the Shaaka application is built using the **Django** web framework in conjunction with **Django REST Framework (DRF)**. This forms a robust API-driven backend that serves a frontend application (like React/Flutter).

### Key Technologies & Libraries:
*   **Framework**: Django & Django REST Framework (DRF).
*   **Database**: PostgreSQL (specifically hosted on Neon DB, as indicated by the connection strings and managed tables). Data interaction is managed entirely by the **Django ORM**, ensuring safety against SQL injection and easy migrations.
*   **Authentication mechanism**: Custom authentication. The user model does not rely on Django's default `User` model but instead uses `UserProfile` with passwords hashed manually using the `bcrypt` library.
*   **Media Storage**: Cloudinary is integrated to handle image and file uploads (e.g., product images, donation proofs).
*   **API Documentation**: `drf_spectacular` (Swagger) is used for generating standardized OpenAPI specifications.
*   **CORS**: `django-cors-headers` is employed to allow cross-origin requests securely from the frontend.

### Project Structure (App-Based Architecture):
The codebase is modularly divided into "apps", each responsible for a distinct business domain. This is a crucial Django best practice:
1.  **`users`**: Handles user profiles, roles, authentication, and addresses.
2.  **`products`**: Manages the core catalog, variants, reviews, wished items, and promotional banners.
3.  **`orders`**: Responsible for the shopping cart and checkout pipeline.
4.  **`donations`**: Manages philanthropic features (food, clothes, money, and education donations).

---

## 2. Database Design & Models (In Detail)

The database schema is highly relational, utilizing Foreign Keys for associations and ensuring data integrity. Here is an app-by-app breakdown of the models:

### A. Users App
**1. `UserProfile` (`user_profiles` table)**
*   **Purpose**: Acts as the central identity model. Instead of extending Django's built-in `AbstractUser`, it's a completely custom model.
*   **Roles**: Managed via the `category` field (`Customer`, `Vendor`, `Women Merchant`). This is important—it means a unified table is used for all actors, differentiated by a role column (Single Table approach).
*   **Security**: Stores passwords securely in `password_hash` using `bcrypt` salting and hashing. Native `set_password` and `check_password` utility methods handles verification securely.
*   **Key Fields**: `full_name`, `mobile_number` (Unique Identifier for login), geographic coordinates (`latitude`, `longitude`), and `profile_pic_url`.

**2. `UserAddress` (`user_addresses` table)**
*   **Purpose**: A One-to-Many relationship with `UserProfile`. Allows a user to have multiple delivery addresses.
*   **Features**: Includes an `is_default` boolean. When a customer marks an address as default, a custom `save()` method is triggered to un-default all other addresses for that specific user.

### B. Products App
**1. `Product` (`products` table)**
*   **Purpose**: The central entity of the marketplace. Represents an item sold by a vendor.
*   **Relationships**: Links to `UserProfile` (Vendor) via a Foreign Key.
*   **Performance Optimization**: Uses **Denormalization**. Instead of querying all reviews and calculating the average dynamically on every page load, it has `average_rating` and `rating_count` fields. These are updated automatically through **Django Signals** (`post_save` and `post_delete` on reviews). 
*   **Categories**: Encompasses a wide range of predefined choices (Fruits, Vegetables, Dairy, Millets, etc.).

**2. `ProductImage`, `ProductVariant`**
*   **Variants**: Allows products to be sold in different weights or sizes (e.g., 1kg vs 500g) with distinct pricing and stock tracking.
*   **Images**: A One-to-Many tie to `Product`, allowing gallery views without bloating the main product table.

**3. `ProductReview` & `WishlistItem`**
*   **Review Rule**: Uses `unique_together = ('product', 'user')` to strictly enforce that a user can only leave *one* review per product.
*   **Wishlist**: Connects a User and a Product in a Many-to-Many structural concept (implemented as a pivot table with a timestamp).

### C. Orders App
**1. `Cart` & `CartItem`**
*   **Purpose**: Temporary storage for items intending to be purchased.
*   **Cart**: A `OneToOneField` with `UserProfile`—each user has exactly one active cart.
*   **CartItem**: Links to a `Product`. The total price logic smartly checks if a specific `ProductVariant` exists (e.g., tiered pricing); if not, it calculates using standard base price metrics. `unique_together` dictates that identical items with the same unit value don't spawn new rows but update quantities instead.

**2. `Order` & `OrderItem`**
*   **Checkout Snapshot**: When a Cart converts to an Order, the `Order` model captures a static snapshot of the address (`shipping_address`, `city`, `pincode`).
*   **Immutability Strategy**: Similarly, `OrderItem` captures `price_at_purchase` and `product_name`. *Why is this important?* If a vendor later deletes a product or changes its price, historical order receipts remain accurate and unchanged. This is a classic e-commerce database design pattern.
*   **Flow**: Supported statuses (`Placed`, `Processing`, `Shipped`, `Delivered`, `Cancelled`).

**3. `CancelledOrder`**
*   **Purpose**: Extending the base Order table logically to store cancellation metadata (`reason`) without cluttering the main `orders` table.

### D. Donations App
**1. `Donation` (`donations` table)**
*   **Purpose**: A multi-purpose table representing different charitable contributions.
*   **Design Choice (Single Table Inheritance approach)**: Instead of creating 4 different tables for Food, Clothes, Money, and Education, all fields are placed in a single `Donation` table. Nullable fields are utilized depending on the `donation_type`.
    *   *If Money*: Uses `amount`, `payment_screenshot`.
    *   *If Food/Clothes*: Uses `item_name`, `quantity`, `pickup_address`.
    *   *If Education*: Uses `profession`, `subject`, `time_slot`.
*   **Pros**: Simplifies querying all donations a user has made.

---

## 3. Key Technical Decisions & Interview Talking Points

If asked _"Why did you build it this way?"_, here is your arsenal:

1.  **Why Django Signals for Ratings?**
    *   **Answer**: "To optimize database reads. Calculating the average rating of a product by querying hundreds of review rows on every catalog page load is heavy. By using Django `post_save` and `post_delete` signals on the `ProductReview` model, we update the `average_rating` column directly on the `Product` table. This denormalization makes read operations extremely fast."
2.  **Why Custom bcrypt instead of Django’s native auth?**
    *   **Answer**: "We needed tight control over out authentication payload, particularly to use `mobile_number` as the primary identifier instead of a standard username/email. While Django allows custom user models, manually wrapping `bcrypt` in our `UserProfile` gave us maximum flexibility for integration with OTP/Mobile-first designs."
3.  **Why snapshot prices and addresses in `Order` and `OrderItem`?**
    *   **Answer**: "For historical data integrity. If a vendor updates the price of 'Apples' tomorrow from ₹100 to ₹150, the receipt for last week's order must still say ₹100. By copying `price_at_purchase` and `shipping_address` as static text during checkout instead of executing a join, we achieve immutability for past orders."
4.  **Database Scalability Choice**:
    *   **Answer**: "We used PostgreSQL via Neon DB. We chose it because Neon offers serverless architecture, which scales compute to zero when idle (cost-effective) and scales up instantly during traffic spikes. By utilizing Django ORM, the application remains database-agnostic largely, but takes advantage of Postgres durability."

## 4. Summary of Data Flow (The "Order Process")
1.  **User logs in** (matches `mobile_number` and verifies `bcrypt` hash).
2.  **Browses Products** (queries `Product` table, reads denormalized `average_rating`).
3.  **Adds to Cart** (inserts/updates `CartItem` linked to User's singleton `Cart`).
4.  **Checkout** (creates an `Order`, copies `CartItem` data over to `OrderItem` noting the *exact price*, clears the `Cart`).
5.  **Vendor Fulfillment** (updates `Order` status: Processing -> Shipped -> Delivered).
