module yaafreka::platform {
    use sui::coin::{Coin, TreasuryCap, mint, into_balance, value, take};
    use sui::balance::{Balance, join};
    use sui::sui::SUI;
    use sui::event;
    use sui::tx_context::sender;
    use sui::object:: new;
    use sui::clock::Clock;
    use std::string;

    //==============================================================================================
    // Error Codes
    //==============================================================================================
    const EInvalidAccess: u64 = 1;
    const ETipTooLow: u64 = 2;
    const ENoTokensToStake: u64 = 3;

    //==============================================================================================
    // Structs
    //==============================================================================================
    /// User Profile representing DID (Decentralized Identity)
    public struct UserProfile has key, store {
        id: UID,
        wallet: address,
        name: string::String,
        bio: string::String,
        preferences: string::String,
        access_granted: bool,
    }

    /// Content represented as NFTs for videos
    public struct VideoNFT has key, store {
        id: UID,
        title: string::String,
        description: string::String,
        url: string::String, // IPFS or decentralized storage link
        creator: address,
        ownership: address, // The current owner of the NFT
        price: u64, // Price for pay-per-view or exclusive access
        is_for_sale: bool,
    }

    /// Event for tracking tips or donations
    public struct TipEvent has copy, drop {
        viewer: address,
        creator: address,
        amount: u64,
    }

    /// Governance proposal
    public struct Proposal has key, store {
        id: UID,
        title: string::String,
        description: string::String,
        yes_votes: u64,
        no_votes: u64,
        quorum: u64,
        passed: bool,
    }

    /// Subscriber model for users who subscribe to creators
    public struct Subscription has key, store {
        id: UID,
        creator: address,
        subscriber: address,
        expiration_time: u64, // Expiration timestamp for subscription
    }

    /// Stake for promoting content
    public struct Stake has key, store {
        id: UID,
        staker: address,
        balance: Balance<SUI>, // Balance to track staked tokens
    }

    /// Referral struct for content sharing
    public struct Referral has key, store {
        id: UID,
        referrer: address,
    }

    /// Access control for data ownership and privacy
    public struct DataAccess has key, store {
        id: UID,
    }

    //==============================================================================================
    // User Account Management (Decentralized Identity - DID)
    //==============================================================================================
    public entry fun register_user(
    name: string::String, 
    bio: string::String, 
    preferences: string::String, 
    ctx: &mut TxContext
) {
    let wallet = sender(ctx);

    // Check if the user profile already exists
    assert!(UserProfile::exists(wallet) == false, EProfileAlreadyExists);

    // Create a new user profile
    let profile = UserProfile {
        id: new(ctx),
        wallet,
        name,
        bio,
        preferences,
        access_granted: false,
    };

    // Transfer ownership of the profile to the user's wallet
    transfer::transfer(profile, wallet);
}


    //==============================================================================================
    // Content Upload (Video NFTs)
    //==============================================================================================
    /// Mint a new Video NFT for every video uploaded
    public entry fun upload_video(
    title: string::String, 
    description: string::String, 
    url: string::String, 
    price: u64, 
    ctx: &mut TxContext
) {
    let creator = sender(ctx);

    // Validate the URL field
    assert!(!string::is_empty(&url), EInvalidURL);
    assert!(string::starts_with(&url, "http://") || string::starts_with(&url, "https://"), EInvalidURLFormat);

    // Create a new VideoNFT
    let video_nft = VideoNFT {
        id: new(ctx),
        title,
        description,
        url,
        creator,
        ownership: creator,
        price,
        is_for_sale: true,
    };

    // Transfer ownership of the VideoNFT to the creator
    transfer::transfer(video_nft, creator);
}


    //==============================================================================================
    // Decentralized Video Streaming
    //==============================================================================================
    public entry fun stream_video(
    nft: &VideoNFT, 
    viewer: address, 
    subscriptions: vector<Subscription>, // A vector of active subscriptions
    ctx: &mut TxContext
) {
    // Ensure the video is for sale or the viewer has purchased it
    let has_purchased = nft.ownership == viewer;
    assert!(has_purchased || nft.is_for_sale == false, EInvalidAccess);

    // Check if the viewer has a valid subscription to the creator
    let mut has_valid_subscription = false;
    let current_time = sui::clock::now(ctx); // Get the current timestamp

    // Loop through the subscriptions to check if the viewer is subscribed to the creator
    let creator = nft.creator;
    for subscription in &subscriptions {
        if subscription.subscriber == viewer && subscription.creator == creator && subscription.expiration_time > current_time {
            has_valid_subscription = true;
            break;
        }
    }

    // Ensure the viewer either purchased the video or has a valid subscription
    assert!(has_purchased || has_valid_subscription, EInvalidSubscriptionOrPurchase);

    // Stream the video (proceed with the streaming logic)
    // Emit an event for tracking purposes
    event::emit(viewer, creator, nft.url);
}


    //==============================================================================================
    // Revenue Sharing (Creator Royalties)
    //==============================================================================================
    public entry fun distribute_revenue(
    cap: &mut TreasuryCap<SUI>, 
    amount: u64, 
    creator: address, 
    platform: address, 
    ctx: &mut TxContext
) {
    // Ensure the total amount to be distributed is not zero
    assert!(amount > 0, EInvalidAmount);

    // Calculate the shares
    let platform_share = amount / 10; // 10% for the platform
    let creator_share = amount - platform_share; // Remaining 90% for the creator

    // Validate shares
    assert!(creator_share >= 0, EInvalidShare);
    assert!(platform_share >= 0, EInvalidShare);

    // Transfer the shares
    transfer::public_transfer(mint(cap, creator_share, ctx), creator);
    transfer::public_transfer(mint(cap, platform_share, ctx), platform);
}

    //==============================================================================================
    // Ad-Free Subscription Model
    //==============================================================================================
    /// Allow users to subscribe to a creator for ad-free content
    public entry fun subscribe_to_creator(
        creator: address, 
        subscription_period: u64, 
        clock: &Clock, 
        ctx: &mut TxContext
    ) {
        let subscriber = sender(ctx);
        let expiration_time = clock.timestamp_ms() + subscription_period;
        let subscription = Subscription {
            id: new(ctx),
            creator,
            subscriber,
            expiration_time,
        };
        transfer::transfer(subscription, subscriber);
    }

    //==============================================================================================
    // Tipping and Donations
    //==============================================================================================
    /// Tip the creator for their content
    public entry fun tip_creator(
        cap: &mut TreasuryCap<SUI>, 
        creator: address, 
        amount: u64, 
        ctx: &mut TxContext
    ) {
        let viewer = sender(ctx);
        assert!(amount > 0, ETipTooLow);
        let tip_event = TipEvent {
            viewer,
            creator,
            amount,
        };
        event::emit(tip_event);
        transfer::public_transfer(mint(cap, amount, ctx), creator);
    }

    //==============================================================================================
    // Decentralized Governance (DAO)
    //==============================================================================================
    /// Submit a proposal for decentralized governance
    public entry fun submit_proposal(
        title: string::String, 
        description: string::String, 
        quorum: u64, 
        ctx: &mut TxContext
    ) {
        let proposal = Proposal {
            id: new(ctx),
            title,
            description,
            yes_votes: 0,
            no_votes: 0,
            quorum,
            passed: false,
        };
        transfer::transfer(proposal, sender(ctx));
    }

    /// Vote on a governance proposal
    public entry fun vote_on_proposal(
        proposal: &mut Proposal, 
        vote: bool, 
        _ctx: &mut TxContext
    ) {
        if (vote) {
            proposal.yes_votes = proposal.yes_votes + 1;
        } else {
            proposal.no_votes = proposal.no_votes + 1;
        };
        let total_votes = proposal.yes_votes + proposal.no_votes;
        if (total_votes >= proposal.quorum) {
            proposal.passed = proposal.yes_votes > proposal.no_votes;
        }
    }

    //==============================================================================================
    // Content Curation and Recommendations (Tokenized Voting System)
    //==============================================================================================
    /// Stake tokens to promote content
    public entry fun stake_to_promote(
        _nft: &mut VideoNFT, 
        amount: Coin<SUI>, 
        ctx: &mut TxContext
    ) {
        let staker = sender(ctx);
        assert!(value(&amount) > 0, ENoTokensToStake);
        let stake_balance = into_balance(amount);
        let stake = Stake {
            id: new(ctx),
            staker,
            balance: stake_balance,
        };
        transfer::transfer(stake, staker);
    }

    /// Reward staker if content performs well
    public entry fun reward_staker(
        stake: &mut Stake, 
        reward: u64, 
        cap: &mut TreasuryCap<SUI>, 
        ctx: &mut TxContext
    ) {
        let reward_balance = into_balance(mint(cap, reward, ctx));
        join(&mut stake.balance, reward_balance);
        let balance_coin = take(&mut stake.balance, reward, ctx); // Use take to move the balance
        transfer::public_transfer(balance_coin, stake.staker);
    }

    //==============================================================================================
    // Pay-Per-View Model
    //==============================================================================================
    /// Lock video behind a paywall for pay-per-view access
    public entry fun pay_for_video(
    nft: &mut VideoNFT, 
    viewer: address, 
    cap: &mut TreasuryCap<SUI>, 
    ctx: &mut TxContext
) {
    // Ensure the video is still for sale
    assert!(nft.is_for_sale, EVideoNotForSale);

    // Check if the video price is valid (greater than 0)
    assert!(nft.price > 0, EInvalidPrice);

    // Mint the payment coin for the video price
    let payment = mint(cap, nft.price, ctx);

    // Transfer the payment to the video creator
    transfer::public_transfer(payment, nft.creator);

    // Transfer ownership of the NFT to the viewer
    nft.ownership = viewer;

    // Mark the video as no longer for sale
    nft.is_for_sale = false;
}


    //==============================================================================================
    // Peer-to-Peer Content Sharing (Referral System)
    //==============================================================================================
    /// Generate a referral link for content
    public entry fun generate_referral_link(
        _nft: &VideoNFT, 
        _referrer: address, 
        _ctx: &mut TxContext
    ): string::String {
        string::utf8(b"referral://")
    }

    /// Track referrals and reward referrer
    public entry fun track_referral(
        cap: &mut TreasuryCap<SUI>, 
        referral: &Referral, 
        ctx: &mut TxContext
    ) {
        let referrer = referral.referrer;
        transfer::public_transfer(mint(cap, 100, ctx), referrer);
    }

    //==============================================================================================
    // Tokenized Rewards for Content Viewing
    //==============================================================================================
    /// Reward users for watching content
    public entry fun reward_viewing_time(
        cap: &mut TreasuryCap<SUI>, 
        _nft: &VideoNFT, 
        viewer: address, 
        time_watched: u64, 
        reward_rate: u64, 
        ctx: &mut TxContext
    ) {
        let reward = time_watched * reward_rate;
        transfer::public_transfer(mint(cap, reward, ctx), viewer);
    }

    //==============================================================================================
    // NFT Market for Exclusive Content
    //==============================================================================================
    /// Mint an exclusive NFT for premium content
    public entry fun mint_exclusive_nft(
        title: string::String, 
        description: string::String, 
        price: u64, 
        creator: address, 
        ctx: &mut TxContext
    ) {
        let nft = VideoNFT {
            id: new(ctx),
            title,
            description,
            url: string::utf8(b"exclusive_content"),
            creator,
            ownership: creator,
            price,
            is_for_sale: true,
        };
        transfer::transfer(nft, creator);
    }

    /// Buy an exclusive NFT
    public entry fun buy_exclusive_nft(
        cap: &mut TreasuryCap<SUI>, 
        nft: &mut VideoNFT, 
        buyer: address, 
        ctx: &mut TxContext
    ) {
        assert!(nft.is_for_sale, EInvalidAccess);
        transfer::public_transfer(mint(cap, nft.price, ctx), nft.creator);
        nft.ownership = buyer;
        nft.is_for_sale = false;
    }

    //==============================================================================================
    // Data Ownership and Privacy
    //==============================================================================================
    /// Grant access to personal data
    public entry fun grant_data_access(
        user: &mut UserProfile, 
        access: bool, 
        _ctx: &mut TxContext
    ) {
        user.access_granted = access;
    }

    /// Revoke access to personal data
    public entry fun revoke_data_access(
        user: &mut UserProfile, 
        _ctx: &mut TxContext
    ) {
        user.access_granted = false;
    }
}
