PredictWise
===========

A decentralized, on-chain prediction market smart contract for creating, participating in, and resolving markets based on real-world events.

* * * * *

Overview
--------

**PredictWise** is a Clarity smart contract that enables anyone to launch and participate in decentralized prediction markets. Users can stake on outcomes, and designated oracles resolve markets, ensuring transparent and fair payouts. The contract also provides advanced analytics and reporting for each market.

* * * * *

Features
--------

-   **Market Creation:** Anyone can create a market with a question, description, outcomes, deadlines, and an oracle.

-   **Staking:** Users stake tokens on their predicted outcome before the participation deadline.

-   **Market Resolution:** Only the assigned oracle can resolve a market by selecting the winning outcome after the resolution deadline.

-   **Reward Claiming:** Participants who staked on the correct outcome can claim proportional rewards.

-   **Analytics:** Generate advanced analytics and reporting for each market, including confidence scores and volatility estimates.

* * * * *

Contract Functions
------------------

Read-Only Functions
-------------------

-   `get-market(market-id)`: Retrieve market details.

-   `get-market-stake(market-id, outcome)`: Get total stake for a specific outcome.

-   `get-user-stake(market-id, user, outcome)`: Get a user's stake on a specific outcome.

-   `get-next-market-id()`: View the next market ID to be assigned.

Public Functions
----------------

-   `create-market(question, description, possible-outcomes, participation-deadline, resolution-deadline, oracle)`: Create a new prediction market.

-   `place-stake(market-id, outcome, amount)`: Stake tokens on a specific outcome.

-   `resolve-market(market-id, winning-outcome)`: Resolve a market (oracle only).

-   `claim-rewards(market-id)`: Claim rewards if you staked on the winning outcome.

-   `generate-market-analytics-report(market-id)`: Generate and retrieve analytics for a market.

* * * * *

Error Codes
-----------

| Code | Description |
| --- | --- |
| 100 | Not authorized |
| 101 | Market closed |
| 102 | Market not resolved |
| 103 | Invalid outcome |
| 104 | Insufficient funds |
| 105 | Market not found |
| 106 | Already resolved |
| 107 | Invalid amount |
| 108 | Deadline passed |

* * * * *

Usage
-----

1.  **Create a Market:**\
    Call `create-market` with your question, description, outcomes, deadlines, and oracle address.

2.  **Participate:**\
    Use `place-stake` to stake tokens on your predicted outcome before the participation deadline.

3.  **Resolve:**\
    After the resolution deadline, the oracle calls `resolve-market` to select the winning outcome.

4.  **Claim Rewards:**\
    Participants who staked on the winning outcome use `claim-rewards` to receive their share.

5.  **Analytics:**\
    Call `generate-market-analytics-report` for market insights and statistics.

* * * * *

Contribution
------------

Contributions are welcome! Please:

-   Fork the repository and create a feature branch.

-   Submit clear pull requests with descriptive messages.

-   Open issues for bugs or feature requests.

-   Follow the [Contributor Covenant](https://www.contributor-covenant.org/) code of conduct.

* * * * *

License
-------

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

* * * * *

Related
-------

-   [Stacks Clarity Language Documentation](https://docs.stacks.co/docs/write-smart-contracts/clarity)

-   [OpenZeppelin Community](https://forum.openzeppelin.com/)

* * * * *

Disclaimer
----------

This contract is provided as-is for educational and research purposes. Use at your own risk. Always audit and test thoroughly before deploying to mainnet.
