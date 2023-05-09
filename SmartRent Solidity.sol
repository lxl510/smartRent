pragma solidity <=0.5.1;  

// use 0.5.1 complier 
// 1 eth = 1000000000000000000 wei 

// address = 123 or any number 
// Rent =  20 eth = 20000000000000000000 wei  
// deposit = 2 eth = 2000000000000000000
// month of stay = 10 months, for easy of calculation
// pay occation = 1 or 2 or month of stay, idea is pay in full, half, or monthly

// 1. Enter landlord and tenant address 
// 2. They both needs to agree on the same information, property address, total amount of rent, and length of stay
// 3. Pay deposit, show deposit,deadline
// 4. Pay rent, see monthly rent, time left, deadline change
// 5. Destory Contract after deadline
// 6. Money back 

contract smartLease{
    
     // Initiate variables
     address payable public landlordAddress;
     address payable public tenantAddress;
     uint public propertyAddress;
     uint public deposit;
     uint public rent_remain; 
     uint public monthly_payment;
     uint public payOccasion;
     uint public months_of_stay;
     uint public deadline;
     uint public number_of_times_left;
    
    // Initiate contract by using landlordAddress and tenantAddress
    constructor(address payable _landlordAddress, address payable _tenantAddress) public {
        require (_landlordAddress != _tenantAddress, "Landlord can't have the same address as the tenant");
        require (msg.sender == _landlordAddress, "Only landlord can start a contract");
        landlordAddress = _landlordAddress;
        tenantAddress = _tenantAddress;
    }
    
    //Grouping these variables under the property.
    struct Property{
        uint rentAmount;
        uint rentAddress;
        uint depositAmount;
        bool contractCreated;
        bool paidDeposit;
    }
    //maps the address the property class, we can also create an array to story many tenant if landlord owns more than 1 house. 
    mapping(address => Property) property; 
    
    // this part is the modifier to limit access to the contract once it starts running
    modifier onlyTenant(){
        require(msg.sender == tenantAddress, "Only tenant can use this function");
        _;
    }

     modifier onlyLandlord(){
        require(msg.sender == landlordAddress , "Only landlord can use this function");
        _;
    }

    // This is a public function, however, only the landlord can use it. 
    function landlordVerify(uint _propertyAddress, uint _total_rentAmount, uint _depositAmount, uint _months_of_stay) onlyLandlord public  {
        property[tenantAddress].rentAddress = _propertyAddress;
        property[tenantAddress].rentAmount = _total_rentAmount; 
        property[tenantAddress].depositAmount = _depositAmount;
        months_of_stay = _months_of_stay; 

    }
    
    // tenant verify the address, total rent, deposit
    function tenantVerify(uint _propertyAddress, uint _total_rentAmount, uint _depositAmount, uint _payOccasion, uint _months_of_stay) onlyTenant public {
        require (_total_rentAmount == property[tenantAddress].rentAmount, "Contact owner, rent amount does not match");
        require (_propertyAddress == property[tenantAddress].rentAddress, "Contact owner, address  does not match");
        require (_depositAmount == property[tenantAddress].depositAmount, "Contact owner, deposit amount does not match record");
        require (_months_of_stay == months_of_stay, "Contact owner, stay duration does not match record");
        require (_payOccasion == 1 || _payOccasion == 2 || _payOccasion == months_of_stay, "You can only pay monthly, pay half, or pay in full");
        property[tenantAddress].contractCreated = true;
        payOccasion = _payOccasion;
        monthly_payment = _total_rentAmount / _payOccasion;
        rent_remain = property[tenantAddress].rentAmount; 
    }
      
    // this function take deposit from the renter. It checks whether the amount matches the required amount, and required that the contract is created. 
    // The condition for the contract to be created is that the tenant verify steps went through. 
    function payDeposit () public payable onlyTenant {
        require (msg.value == property[tenantAddress].depositAmount, "Deposit Amount does not match the record");
        require (property[tenantAddress].contractCreated == true, "Contract has not been created yet, contact the landlord");
        require (property[tenantAddress].paidDeposit == false);
        deposit += msg.value;
        property[tenantAddress].paidDeposit = true;
        // for testing purpose, set the timer to lower. 
        number_of_times_left = payOccasion;
        // For testing
        deadline = now + 20 seconds;
        // In real time, we need to make adjustment on paying habit of tennat, we are giving in total 1 month + 7 days to pay rent. 
        // deadline = now + ((months_of_stay / payOccasion) months) + 7 days ;
    }

    function payRent() public payable {
        require(msg.sender != landlordAddress, "landlord can not pay their own rent");
        require (property[tenantAddress].paidDeposit == true);
        require(property[tenantAddress].contractCreated == true, "Contract has not been created yet, contact the landlord");
        require(msg.value == monthly_payment, "The wrong amount of payment is made, check again");
        landlordAddress.transfer(msg.value);
        rent_remain -= msg.value;
        number_of_times_left -= 1; 
        deadline = now + 20 seconds;
        // deadline = now + ((months_of_stay / payOccasion) months);
    }   

    // Return whether deposit is paid or not. 
    function depositPaid() public view returns(bool){
        return (property[tenantAddress].paidDeposit == true);
    }
    
    // Landlord only, destroy the contract when tenant defaults
    function destoryContract() public payable onlyLandlord{
         require(now >= deadline, "It hasn't pass the deadline yet." );
         require(rent_remain != 0, "Tenant already paid all his rent" );
         landlordAddress.transfer(deposit); 
         selfdestruct(landlordAddress);
    }

    // Tenants get their money back once they paid all their deposit 
    function moneyBack() public payable {
         require (rent_remain == 0, "You have not pay all your rent yet!" );
         require (property[tenantAddress].paidDeposit == true);
         tenantAddress.transfer(deposit); 
         selfdestruct(tenantAddress);
    }


}


