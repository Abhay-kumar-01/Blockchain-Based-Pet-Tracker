// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Pet structure to store pet information
    struct Pet {
        uint256 petId;
        string name;
        string breed;
        uint256 age;
        address owner;
        string currentLocation;
        uint256 lastUpdated;
        bool isActive;
    }
    
    // Mappings
    mapping(uint256 => Pet) public pets;
    mapping(address => uint256[]) public ownerToPets;
    mapping(uint256 => address[]) public petLocationHistory;
    
    // State variables
    uint256 private nextPetId;
    uint256 public totalPets;
    
    // Events
    event PetRegistered(uint256 indexed petId, string name, address indexed owner);
    event LocationUpdated(uint256 indexed petId, string newLocation, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed petId, address indexed oldOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyPetOwner(uint256 _petId) {
        require(pets[_petId].owner == msg.sender, "Only pet owner can perform this action");
        require(pets[_petId].isActive, "Pet is not active");
        _;
    }
    
    modifier petExists(uint256 _petId) {
        require(_petId < nextPetId, "Pet does not exist");
        require(pets[_petId].isActive, "Pet is not active");
        _;
    }
    
    constructor() {
        nextPetId = 1;
        totalPets = 0;
    }
    
    // Core Function 1: Register a new pet
    function registerPet(
        string memory _name,
        string memory _breed,
        uint256 _age,
        string memory _initialLocation
    ) public returns (uint256) {
        require(bytes(_name).length > 0, "Pet name cannot be empty");
        require(bytes(_breed).length > 0, "Pet breed cannot be empty");
        require(_age > 0, "Pet age must be greater than 0");
        require(bytes(_initialLocation).length > 0, "Initial location cannot be empty");
        
        uint256 petId = nextPetId;
        
        pets[petId] = Pet({
            petId: petId,
            name: _name,
            breed: _breed,
            age: _age,
            owner: msg.sender,
            currentLocation: _initialLocation,
            lastUpdated: block.timestamp,
            isActive: true
        });
        
        ownerToPets[msg.sender].push(petId);
        petLocationHistory[petId].push(msg.sender);
        
        nextPetId++;
        totalPets++;
        
        emit PetRegistered(petId, _name, msg.sender);
        emit LocationUpdated(petId, _initialLocation, block.timestamp);
        
        return petId;
    }
    
    // Core Function 2: Update pet location
    function updatePetLocation(
        uint256 _petId,
        string memory _newLocation
    ) public onlyPetOwner(_petId) {
        require(bytes(_newLocation).length > 0, "Location cannot be empty");
        
        pets[_petId].currentLocation = _newLocation;
        pets[_petId].lastUpdated = block.timestamp;
        
        petLocationHistory[_petId].push(msg.sender);
        
        emit LocationUpdated(_petId, _newLocation, block.timestamp);
    }
    
    // Core Function 3: Transfer pet ownership
    function transferOwnership(
        uint256 _petId,
        address _newOwner
    ) public onlyPetOwner(_petId) {
        require(_newOwner != address(0), "New owner address cannot be zero");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        address oldOwner = pets[_petId].owner;
        pets[_petId].owner = _newOwner;
        pets[_petId].lastUpdated = block.timestamp;
        
        // Add pet to new owner's list
        ownerToPets[_newOwner].push(_petId);
        
        // Remove pet from old owner's list
        uint256[] storage ownerPets = ownerToPets[oldOwner];
        for (uint256 i = 0; i < ownerPets.length; i++) {
            if (ownerPets[i] == _petId) {
                ownerPets[i] = ownerPets[ownerPets.length - 1];
                ownerPets.pop();
                break;
            }
        }
        
        emit OwnershipTransferred(_petId, oldOwner, _newOwner);
    }
    
    // View function: Get pet details
    function getPetDetails(uint256 _petId) 
        public 
        view 
        petExists(_petId) 
        returns (
            string memory name,
            string memory breed,
            uint256 age,
            address owner,
            string memory currentLocation,
            uint256 lastUpdated
        ) 
    {
        Pet memory pet = pets[_petId];
        return (
            pet.name,
            pet.breed,
            pet.age,
            pet.owner,
            pet.currentLocation,
            pet.lastUpdated
        );
    }
    
    // View function: Get pets owned by an address
    function getPetsByOwner(address _owner) public view returns (uint256[] memory) {
        return ownerToPets[_owner];
    }
    
    // View function: Get pet location history count
    function getLocationHistoryCount(uint256 _petId) public view petExists(_petId) returns (uint256) {
        return petLocationHistory[_petId].length;
    }
    
    // View function: Check if pet exists and is active
    function isPetActive(uint256 _petId) public view returns (bool) {
        return _petId < nextPetId && pets[_petId].isActive;
    }
}
