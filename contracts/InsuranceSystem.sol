// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract InsuranceSystem {
    uint policy_buy_price = 0.01 ether;
    uint policy_claim_price = 0.02 ether;
    string purchased = "Purchased";
    string claimed = "Claimed";

    string[] public policy_statement = [
        "Policy1: If your flight cancels due to Bad Weather, you get 0.02 etherum. With one address you can buy one policy only."
    ];

    struct PolicyPurchased {
        string passenger_name;
        address passenger_address;
        string flight_number;
        string departure_date;
        string departure_city;
        string destination_city;
        string policy_status;
    }

    mapping(address => PolicyPurchased) customers_mapping;

    address payable[] public address_lookup;
    address payable public manager;
    PolicyPurchased[] customers;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    modifier minAmount() {
        require(msg.value == policy_buy_price);
        _;
    }

    modifier maxOnePolicyScheme() {
        require(!checkPolicyStatus());
        _;
    }

    constructor() {
        manager = payable(msg.sender);
    }

    function viw_available_policy() public view returns (string[] memory) {
        return policy_statement;
    }

    function checkPolicyStatus() public view returns (bool) {
        bool check = keccak256(
            abi.encodePacked(customers_mapping[msg.sender].policy_status)
        ) == keccak256(abi.encodePacked(purchased));
        return check;
    }

    function purchase_policy(
        string calldata passenger_name,
        string calldata flight_number,
        string calldata departure_date,
        string calldata departure_city,
        string calldata destination_city
    ) public payable minAmount maxOnePolicyScheme {
        PolicyPurchased memory newCustomer = PolicyPurchased({
            passenger_name: passenger_name,
            passenger_address: msg.sender,
            flight_number: flight_number,
            departure_date: departure_date,
            departure_city: departure_city,
            destination_city: destination_city,
            policy_status: purchased
        });
        customers_mapping[msg.sender] = newCustomer;
        address_lookup.push(payable(msg.sender));
        customers.push(newCustomer);
        manager.transfer(msg.value);
    }

    function view_all_policies()
        public
        view
        restricted
        returns (PolicyPurchased[] memory)
    {
        return customers;
    }

    function view_purchased_policy()
        public
        view
        returns (PolicyPurchased memory)
    {
        return customers_mapping[msg.sender];
    }

    function update_customer_array(address[] memory pay_these) private {
        for (uint i = 0; i < pay_these.length; i++) {
            for (uint j = 0; j < customers.length; j++) {
                if (customers[j].passenger_address == pay_these[i]) {
                    delete customers[j];
                }
            }
        }
    }

    function payIndemnity(
        address[] memory pay_these
    ) public payable restricted {
        require(pay_these.length * policy_claim_price <= msg.value);
        for (uint i = 0; i < pay_these.length; i++) {
            payable(pay_these[i]).transfer(policy_claim_price);
            customers_mapping[pay_these[i]].policy_status = claimed;
        }
        update_customer_array(pay_these);
    }
}
