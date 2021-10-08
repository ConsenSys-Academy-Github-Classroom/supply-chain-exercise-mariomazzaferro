// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
    address public owner;

    uint256 public skuCount;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Received
    }

    struct Item {
        string name;
        uint sku;
        uint price;
        State state;
        address payable seller;
        address payable buyer;
    }

    mapping(uint256 => Item) items;

    /*
     * Events
     */

    // <LogForSale event: sku arg>
    event LogForSale(uint256 sku);

    // <LogSold event: sku arg>
    event LogSold(uint256 sku);

    // <LogShipped event: sku arg>
    event LogShipped(uint256 sku);

    // <LogReceived event: sku arg>
    event LogReceived(uint256 sku);

    /*
     * Modifiers
     */

    // Create a modifer, `isOwner` that checks if the msg.sender is the owner of the contract

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isSeller(uint256 sku) {
        require(msg.sender == items[sku].seller);
        _;
    }

    modifier isBuyer(uint256 sku) {
        require(msg.sender == items[sku].buyer);
        _;
    }

    modifier paidEnough(uint256 sku) {
        require(msg.value >= items[sku].price);
        _;
    }

    modifier checkValue(uint256 _sku) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        items[_sku].buyer.send(amountToRefund);
    }

    // For each of the following modifiers, use what you learned about modifiers
    // to give them functionality. For example, the forSale modifier should
    // require that the item with the given sku has the state ForSale. Note that
    // the uninitialized Item.State is 0, which is also the index of the ForSale
    // value, so checking that Item.State == ForSale is not sufficient to check
    // that an Item is for sale. Hint: What item properties will be non-zero when
    // an Item has been added?

    // modifier forSale
    modifier forSale(uint256 _sku) {
        require(items[_sku].state == State.ForSale);
        _;
    }

    // modifier sold(uint _sku)
    modifier sold(uint256 _sku) {
        require(items[_sku].state == State.Sold);
        _;
    }

    // modifier shipped(uint _sku)
    modifier shipped(uint256 _sku) {
        require(items[_sku].state == State.Shipped);
        _;
    }

    // modifier received(uint _sku)
    modifier received(uint256 _sku) {
        require(items[_sku].state == State.Received);
        _;
    }

    constructor() public {
        // 1. Set the owner to the transaction sender
        owner = msg.sender;
        // 2. Initialize the sku count to 0.
        skuCount = 0;
    }

    function addItem(string memory _name, uint256 _price)
        public
        returns (bool)
    {
        // 1. Create a new item and put in array
        // 2. Increment the skuCount by one
        // 3. Emit the appropriate event
        // 4. return true

        items[skuCount] = Item(
            _name,
            skuCount,
            _price,
            State.ForSale,
            address(uint160(msg.sender)),
            address(uint160(address(0)))
        );

        emit LogForSale(skuCount);

        skuCount = skuCount + 1;

        return true;
    }

    // Implement this buyItem function.
    // 1. it should be payable in order to receive refunds
    // 2. this should transfer money to the seller,
    // 3. set the buyer as the person who called this transaction,
    // 4. set the state to Sold.
    // 5. this function should use 3 modifiers to check
    //    - if the item is for sale,
    //    - if the buyer paid enough,
    //    - check the value after the function is called to make
    //      sure the buyer is refunded any excess ether sent.
    // 6. call the event associated with this function!
    function buyItem(uint256 sku)
        public
        payable
        forSale(sku)
        paidEnough(sku)
        checkValue(sku)
    {
        items[sku].seller.send(items[sku].price);
        items[sku].buyer = address(uint160(msg.sender));
        items[sku].state = State.Sold;
        emit LogSold(sku);
    }

    // 1. Add modifiers to check:
    //    - the item is sold already
    //    - the person calling this function is the seller.
    // 2. Change the state of the item to shipped.
    // 3. call the event associated with this function!
    function shipItem(uint256 sku) public sold(sku) isSeller(sku) {
        items[sku].state = State.Shipped;
        emit LogShipped(sku);
    }

    // 1. Add modifiers to check
    //    - the item is shipped already
    //    - the person calling this function is the buyer.
    // 2. Change the state of the item to received.
    // 3. Call the event associated with this function!
    function receiveItem(uint256 sku) public shipped(sku) isBuyer(sku) {
        items[sku].state = State.Received;
        emit LogReceived(sku);
    }

    // Uncomment the following code block. it is needed to run tests
    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
