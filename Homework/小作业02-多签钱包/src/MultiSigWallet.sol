// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MultiSigWallet {
    // ========== 数据结构 ==========

    struct Transaction {
        uint256 confirmationCount;
        uint256 value;
        address to;
        bool executed;
        bytes data;
    }

    // ========== 状态变量 ==========

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // ========== Custom Errors ==========

    error NotOwner();
    error OwnersRequired();
    error InvalidThreshold();
    error InvalidOwner();
    error DuplicateOwner();
    error AlreadyOwner();
    error CannotRemoveOwner();
    error InvalidAddress();
    error TxNotExist();
    error AlreadyExecuted();
    error AlreadyConfirmed();
    error NotConfirmed();
    error NotEnoughConfirmations();
    error ExecutionFailed();

    // ========== 事件 ==========

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);
    event ThresholdChanged(uint256 newThreshold);

    // ========== 修饰符 ==========

    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxNotExist();
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert AlreadyExecuted();
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert AlreadyConfirmed();
        _;
    }

    // ========== 构造函数 ==========

    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        if (_owners.length == 0) revert OwnersRequired();
        if (_numConfirmationsRequired == 0 || _numConfirmationsRequired > _owners.length)
            revert InvalidThreshold();
        for (uint256 i = 0; i < _owners.length; i++) {
            if (_owners[i] == address(0)) revert InvalidOwner();
            if (isOwner[_owners[i]]) revert DuplicateOwner();
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // ========== 接收 ETH ==========

    receive() external payable {
        // TODO：触发 Deposit 事件
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    fallback() external payable {
        // TODO：触发 Deposit 事件
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // ========== 所有者管理 ==========

    function addOwner(address _owner) external onlyOwner {
        if (_owner == address(0)) revert InvalidOwner();
        if (isOwner[_owner]) revert AlreadyOwner();
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAdded(_owner);
    }

    function removeOwner(address _owner) external onlyOwner {
        if (!isOwner[_owner]) revert NotOwner();
        if (owners.length - 1 < numConfirmationsRequired) revert CannotRemoveOwner();
        isOwner[_owner] = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }
        emit OwnerRemoved(_owner);
    }

    function changeThreshold(uint256 _newThreshold) external onlyOwner {
        if (_newThreshold == 0 || _newThreshold > owners.length) revert InvalidThreshold();
        numConfirmationsRequired = _newThreshold;
        emit ThresholdChanged(_newThreshold);
    }

    // ========== 交易提案 ==========

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (uint256 txIndex) {
        if (_to == address(0)) revert InvalidAddress();
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmationCount: 0
            })
        );
        txIndex = transactions.length - 1;
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    // ========== 确认机制 ==========

    function confirmTransaction(
        uint256 _txIndex
    )
        external
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        transactions[_txIndex].confirmationCount++;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function revokeConfirmation(
        uint256 _txIndex
    ) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert NotConfirmed();
        transactions[_txIndex].confirmationCount--;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    // ========== 执行交易 ==========

    function executeTransaction(
        uint256 _txIndex
    ) external onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage txn = transactions[_txIndex];
        if (txn.confirmationCount < numConfirmationsRequired) revert NotEnoughConfirmations();

        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert ExecutionFailed();
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    // ========== 查询辅助函数 ==========

    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    function getThreshold() external view returns (uint256) {
        return numConfirmationsRequired;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(
        uint256 _txIndex
    )
        external
        view
        txExists(_txIndex)
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmationCount
        )
    {
        Transaction storage txn = transactions[_txIndex];
        return (txn.to, txn.value, txn.data, txn.executed, txn.confirmationCount);
    }

    function getConfirmationCount(
        uint256 _txIndex
    ) external view txExists(_txIndex) returns (uint256) {
        return transactions[_txIndex].confirmationCount;
    }

    function isTransactionConfirmed(
        uint256 _txIndex
    ) external view txExists(_txIndex) returns (bool) {
        return isConfirmed[_txIndex][msg.sender];
    }

    function canExecute(
        uint256 _txIndex
    ) external view txExists(_txIndex) returns (bool) {
        return
            !transactions[_txIndex].executed &&
            transactions[_txIndex].confirmationCount >=
            numConfirmationsRequired;
    }
}
