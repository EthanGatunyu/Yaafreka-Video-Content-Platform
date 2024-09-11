## Yaafreeka video content Platform Documentation 


### **Introduction to Yaafreeka Platform**
Yaafreeka is a decentralized content-sharing platform built using the Sui blockchain framework. The platform leverages the principles of decentralized identity (DID), content ownership through NFTs, decentralized video streaming, creator monetization, community-driven governance, and privacy-preserving user data access.

The platform enables users to upload video content, which is minted as Non-Fungible Tokens (NFTs), participate in decentralized video streaming, earn revenue through tips, subscriptions, and pay-per-view models, and manage their data and content in a secure and transparent manner.



### **Platform Overview and Purpose**
The purpose of the Yaafreeka platform is to decentralize content creation, sharing, and monetization, giving creators full control over their content, revenue generation, and user interactions. The platform provides a wide array of features, such as:

- **Decentralized Identity (DID)**: Users can register a profile (DID) on the blockchain.
- **Video NFTs**: Videos are uploaded as NFTs that represent content ownership and can be bought or sold.
- **Monetization**: Creators earn through tips, subscriptions, and pay-per-view models.
- **Community Governance**: Users can propose and vote on platform changes via a DAO.
- **Privacy & Data Ownership**: Users maintain control over their personal data and decide who can access it.
- **Content Curation**: Users can stake tokens to promote content.
- **Referral System**: Content sharing and referral links allow users to earn rewards for referring new viewers.

The platform is ideal for creators who want full control over their revenue and content, as well as users who seek transparency, ownership, and privacy in the content-sharing ecosystem.


### **Error Codes**
- **EInvalidAccess (1)**: Thrown when a user tries to access content or perform an action they are not authorized to.
- **ETipTooLow (2)**: Triggered when a tip amount is too small.
- **ENoTokensToStake (3)**: Occurs when a user attempts to stake an insufficient token amount for content promotion.


### **Structs and Their Purpose**
1. **UserProfile**
   - Represents the decentralized identity (DID) of the user.
   - Stores information like wallet address, name, bio, preferences, and access status.
   
   #### Struct
   public struct UserProfile has key, store {
       id: UID,
       wallet: address,
       name: string::String,
       bio: string::String,
       preferences: string::String,
       access_granted: bool,
   }


2. **VideoNFT**
   - Represents video content as NFTs on the platform.
   - Stores metadata like title, description, content URL, ownership, price, and sale status.
   
   #### Struct
   public struct VideoNFT has key, store {
       id: UID,
       title: string::String,
       description: string::String,
       url: string::String,
       creator: address,
       ownership: address,
       price: u64,
       is_for_sale: bool,
   }
  

3. **TipEvent**
   - Tracks tipping events where users can tip content creators.
   
   #### Struct
   public struct TipEvent has copy, drop {
       viewer: address,
       creator: address,
       amount: u64,
   }
 

4. **Proposal**
   - Represents governance proposals for decentralized voting.
   - Stores voting statistics and proposal details.
   
   #### Struct
   public struct Proposal has key, store {
       id: UID,
       title: string::String,
       description: string::String,
       yes_votes: u64,
       no_votes: u64,
       quorum: u64,
       passed: bool,
   }
   

5. **Subscription**
   - Represents subscription data for users subscribing to ad-free content from creators.
   
   #### Struct
   public struct Subscription has key, store {
       id: UID,
       creator: address,
       subscriber: address,
       expiration_time: u64,
   }


6. **Stake**
   - Represents the balance of tokens a user stakes to promote content.
   
   #### Struct
   public struct Stake has key, store {
       id: UID,
       staker: address,
       balance: Balance<SUI>,
   }
  

7. **Referral**
   - Tracks referrals for the content-sharing system, allowing users to earn rewards for inviting others.
   
   #### Struct
   public struct Referral has key, store {
       id: UID,
       referrer: address,
   }
  

8. **DataAccess**
   - Controls access to users’ personal data, which can be granted or revoked.
   
   #### Struct
   public struct DataAccess has key, store {
       id: UID,
   }
  

## Core Features

### 1. **User Account Management (DID)**
- **Functionality**: This module allows users to create and manage their decentralized identity (DID) on the platform. Each user has a unique profile that stores their personal information like name, bio, and preferences.
- **Logic**: 
  - The function `register_user` registers a user profile (DID) by creating a `UserProfile` object and linking it to the user's wallet address. This profile will be used for interactions on the platform.

#### Function
public entry fun register_user(name: string::String, bio: string::String, preferences: string::String, ctx: &mut TxContext)


### 2. **Content Upload (Video NFTs)**
- **Functionality**: Creators can mint their content as **Video NFTs**. These NFTs represent the creator's ownership of the video, with metadata such as title, description, and a URL pointing to the video file (usually hosted on decentralized storage such as IPFS).
- **Logic**:
  - `upload_video` mints a new `VideoNFT` for each video uploaded. The NFT contains ownership information, price, and sale status.

#### Function
public entry fun upload_video(title: string::String, description: string::String, url: string::String, price: u64, ctx: &mut TxContext)

### 3. **Decentralized Video Streaming**
- **Functionality**: Users can pay to stream videos using decentralized payment channels. Creators are paid directly for their content.
- **Logic**:
  - `stream_video` allows users to stream a video by transferring the payment directly to the creator.

#### Function
public entry fun stream_video(nft: &VideoNFT, _viewer: address, payment: Coin<SUI>, _ctx: &mut TxContext)


### 4. **Revenue Sharing (Creator Royalties)**
- **Functionality**: Revenue earned from content sales, ads, or tips is split between the creator and the platform.
- **Logic**:
  - `distribute_revenue` splits a given amount of tokens between the creator and platform, typically using a 90/10 ratio. The function uses the `mint` function to mint the appropriate amount of tokens to the creator and platform.

#### Function
public entry fun distribute_revenue(cap: &mut TreasuryCap<SUI>, amount: u64, creator: address, platform: address, ctx: &mut TxContext)


### 5. **Ad-Free Subscription Model**
- **Functionality**: Users can subscribe to creators for ad-free content and exclusive benefits.
- **Logic**:
  - `subscribe_to_creator` allows users to subscribe to creators by specifying a subscription period. This creates a `Subscription` object that tracks the expiration of the subscription.

#### Function
public entry fun subscribe_to_creator(creator: address, subscription_period: u64, clock: &Clock, ctx: &mut TxContext)


### 6. **Tipping and Donations**
- **Functionality**: Users can send tips directly to creators to support their work.
- **Logic**:
  - `tip_creator` allows users to tip creators by minting a specific amount of tokens and transferring them to the creator's wallet. The platform also emits a `TipEvent` to track the donation.

#### Function
public entry fun tip_creator(cap: &mut TreasuryCap<SUI>, creator: address, amount: u64, ctx: &mut TxContext)


### 7. **Decentralized Governance (DAO)**
- **Functionality**: The platform supports decentralized governance through proposals and voting, allowing users to vote on platform decisions.
- **Logic**:
  - `submit_proposal` allows users to submit governance proposals. 
  - `vote_on_proposal` enables users to cast votes for or against a proposal, and once a quorum is met, the proposal is passed based on the vote tally.

#### Function
public entry fun submit_proposal(title: string::String, description: string::String, quorum: u64, ctx: &mut TxContext)
public entry fun vote_on_proposal(proposal: &mut Proposal, vote: bool, _ctx: &mut TxContext)


### 8. **Content Curation and Recommendations (Tokenized Voting System)**
- **Functionality**: Users can stake tokens to promote specific content. If the content performs well, stakers are rewarded.
- **Logic**:
  - `stake_to_promote` allows users to stake tokens to promote content. 
  - `reward_staker` rewards the staker if the content performs well by minting tokens and transferring them to the staker's wallet.

#### Function
public entry fun stake_to_promote(_nft: &mut VideoNFT, amount: Coin<SUI>, ctx: &mut TxContext)
public entry fun reward_staker(stake: &mut Stake, reward: u64, cap: &mut TreasuryCap<SUI>, ctx: &mut TxContext)


### 9. **Pay-Per-View Model**
- **Functionality**: Creators can lock videos behind a paywall, and users must pay to view the content.
- **Logic**:
  - `pay_for_video` handles payments for viewing exclusive content. The user pays the specified amount, which is then transferred to the creator.

#### Function
public entry fun pay_for_video(nft: &mut VideoNFT, _viewer: address, cap: &mut TreasuryCap<SUI>, ctx: &mut TxContext)


### 10. **Peer-to-Peer Content Sharing (Referral System)**
- **Functionality**: Users can share referral links to content. When someone uses the referral link to watch or purchase the content, the referrer is rewarded.
- **Logic**:
  - `generate_referral_link` creates a referral link, while `track_referral` rewards the referrer for successful referrals.

#### Function
public entry fun generate_referral_link(_nft: &VideoNFT, _referrer: address, _ctx: &mut TxContext): string::String
public entry fun track_referral(cap: &mut TreasuryCap<SUI>, referral: &Referral, ctx: &mut TxContext)


### 11. **Tokenized Rewards for Content Viewing**
- **Functionality**: Users earn rewards for watching content based on the time they spend.
- **Logic**:
  - `reward_viewing_time` tracks the user's watch time and rewards them based on a set reward rate.

#### Function
public entry fun reward_viewing_time(cap: &mut TreasuryCap<SUI>, _nft: &VideoNFT, viewer: address, time_watched: u64, reward_rate: u64, ctx: &mut TxContext)


### 12. **NFT Market for Exclusive Content**
- **Functionality**: Creators can mint exclusive content as NFTs and sell them on the platform.
- **Logic**:
  - `mint_exclusive_nft` allows creators to mint exclusive content, and `buy_exclusive_nft` allows users to purchase these exclusive NFTs.

#### Function
public entry fun mint_exclusive_nft(title: string::String, description: string::String, price: u64, creator: address, ctx: &mut TxContext)
public entry fun buy_exclusive_nft(cap: &mut TreasuryCap<SUI>, nft: &mut VideoNFT, buyer: address, ctx: &mut TxContext)


### 13. **Data Ownership and Privacy**
- **Functionality**: Users control access to their personal data, with the ability to grant or revoke access.
- **Logic**:
  - `grant_data_access` and `revoke_data_access` allow users to control who can access their personal data.

#### Function
public entry fun grant_data_access(user: &mut UserProfile, access: bool, _ctx: &mut TxContext)
public entry fun revoke_data_access(user: &mut UserProfile, _ctx: &mut TxContext)


## Platform Benefits and Key Points
1. **Decentralization**: Yaafreka uses blockchain to remove intermediaries, ensuring creators have full ownership and control of their content.
2. **Fair Revenue Sharing**: By using smart contracts, creators are compensated in real time based on views, subscriptions, and tips.
3. **Tokenized Rewards**: Viewers and content promoters are incentivized with tokenized rewards, encouraging more active engagement.
4. **DAO Governance**: Platform decisions are governed by the community, ensuring that future platform changes reflect the users' will.
5.**Secure Content and Data**: The use of NFTs for content and smart contracts for privacy ensures that both content and user data are secure and decentralized.

## Why Yaafreka is the Best Solution
- **Creator Control**: Full ownership of content through Video NFTs.
- **Decentralized Payments**: No intermediaries – all payments go directly to creators.
- **User Empowerment**: Users are rewarded for their engagement and participation in platform governance.
- **Transparency**: All transactions and governance are handled on-chain, ensuring transparency and fairness.
- **Innovative Monetization**: Multiple ways for creators to monetize their content, including tips, subscriptions, pay-per-view, and advertising. 

## Conclusion
The Yaafreeka platform is a powerful decentralized content-sharing solution that provides creators and users full control over content, revenue, and data. It eliminates intermediaries, ensuring fair compensation for creators and secure content access for users. This platform's ability to integrate monetization, privacy, governance, and rewards into one seamless blockchain ecosystem makes it one of the best options for decentralized content sharing.

By utilizing NFTs, decentralized identities, and blockchain-based governance, Yaafreeka ensures transparent interactions between creators and consumers, allowing for true ownership and control over digital content.