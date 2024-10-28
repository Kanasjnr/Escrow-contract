// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract FreelanceEscrow {
    struct Escrow {
        address client;
        address freelancer;
        uint256 amount;
        EscrowStatus status;
        bool clientApproval;
        bool freelancerApproval;
    }

    enum EscrowStatus {
        NotStarted,
        InProgress,
        Completed
    }

    mapping(uint256 => Escrow) public escrows;
    uint256 public escrowCount;
    address public owner;

    event EscrowCreated(
        uint256 escrowId,
        address client,
        address freelancer,
        uint256 amount
    );
    event JobCompleted(uint256 escrowId);
    event PaymentReleased(uint256 escrowId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyClient(uint256 _escrowId) {
        require(msg.sender == escrows[_escrowId].client, "Not the client.");
        _;
    }

    modifier onlyFreelancer(uint256 _escrowId) {
        require(
            msg.sender == escrows[_escrowId].freelancer,
            "Not the freelancer."
        );
        _;
    }

    modifier inStatus(uint256 _escrowId, EscrowStatus _status) {
        require(escrows[_escrowId].status == _status, "Invalid status.");
        _;
    }

    function createEscrow(address _freelancer) external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero.");

        escrows[escrowCount] = Escrow({
            client: msg.sender,
            freelancer: _freelancer,
            amount: msg.value,
            status: EscrowStatus.InProgress,
            clientApproval: false,
            freelancerApproval: false
        });

        emit EscrowCreated(escrowCount, msg.sender, _freelancer, msg.value);
        escrowCount++;
    }

    function confirmJobCompletion(uint256 _escrowId) external {
        Escrow storage escrow = escrows[_escrowId];
        require(
            escrow.status == EscrowStatus.InProgress,
            "Job not in progress."
        );

        if (msg.sender == escrow.client) {
            escrow.clientApproval = true;
        } else if (msg.sender == escrow.freelancer) {
            escrow.freelancerApproval = true;
        }

        if (escrow.clientApproval && escrow.freelancerApproval) {
            escrow.status = EscrowStatus.Completed;
            releasePayment(_escrowId);
        }
    }

    function releasePayment(
        uint256 _escrowId
    ) internal inStatus(_escrowId, EscrowStatus.Completed) {
        Escrow storage escrow = escrows[_escrowId];

        payable(escrow.freelancer).transfer(escrow.amount);
        emit PaymentReleased(_escrowId);
    }
}
