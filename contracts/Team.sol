pragma solidity ^0.4.24;
/* -Team Just- v0.2.5
 *
 *         ┌──────────────────────────────────────────────────────────────────────┐
 *         │ Que up intensely spectacular intro music...  In walks, Team Just.    │
 *         │                         Everyone goes crazy.                         │
 *         │ This is a companion to MSFun.  It's a central database of Devs and   │
 *         │ Admin's that we can import to any dapp to allow them management      │
 *         │ permissions.                                                         │
 *         └──────────────────────────────────────────────────────────────────────┘
 *                                ┌────────────────────┐
 *                                │ Setup Instructions │
 *                                └────────────────────┘
 * (Step 1) import this contracts interface into your contract
 * 
 *    import "./TeamInterface.sol";
 *
 * (Step 2) set up the interface to point to the TeamJust contract
 * 
 *    TeamInterface constant TeamJust = TeamInterface(0x464904238b5CdBdCE12722A7E6014EC1C0B66928);
 *
 *    modifier onlyAdmins() {require(TeamJust.isAdmin(msg.sender) == true, "onlyAdmins failed - msg.sender is not an admin"); _;}
 *    modifier onlyDevs() {require(TeamJust.isDev(msg.sender) == true, "onlyDevs failed - msg.sender is not a dev"); _;}
 *                                ┌────────────────────┐
 *                                │ Usage Instructions │
 *                                └────────────────────┘
 * use onlyAdmins() and onlyDevs() modifiers as you normally would on any function
 * you wish to restrict to admins/devs registered with this contract.
 * 
 * to get required signatures for admins or devs
 *       uint256 x = TeamJust.requiredSignatures();
 *       uint256 x = TeamJust.requiredDevSignatures();
 * 
 * to get admin count or dev count 
 *       uint256 x = TeamJust.adminCount();
 *       uint256 x = TeamJust.devCount();
 * 
 * to get the name of an admin (in bytes32 format)
 *       bytes32 x = TeamJust.adminName(address);
 */


import "./library/SafeMath.sol";
import "./library/NameFilter.sol";
import "./library/MSFun.sol";
import "./library/F3Ddatasets.sol";

import "./interface/TeamInterface.sol";
import "./interface/FundForwarderInterface.sol";
import "./interface/PlayerBookReceiverInterface.sol";


contract Team {

    // set dev1
    address constant private DEV_1_ADDRESS = 0x006B332340d355280B3F7aa2b33ea0AB0f5706E9;
    bytes32  constant private DEV_1_NAME = "richer";


    FundForwarderInterface private FundForwarder = FundForwarderInterface(0x0);
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // SET UP MSFun (note, check signers by name is modified from MSFun sdk)
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    MSFun.Data private msData;
    function deleteAnyProposal(bytes32 _whatFunction) onlyDevs() public {MSFun.deleteProposal(msData, _whatFunction);}
    function checkData(bytes32 _whatFunction) onlyAdmins() public view returns(bytes32 message_data, uint256 signature_count) {return(MSFun.checkMsgData(msData, _whatFunction), MSFun.checkCount(msData, _whatFunction));}
    function checkSignersByName(bytes32 _whatFunction, uint256 _signerA, uint256 _signerB, uint256 _signerC) onlyAdmins() public view returns(bytes32, bytes32, bytes32) {return(this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerA)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerB)), this.adminName(MSFun.checkSigner(msData, _whatFunction, _signerC)));}

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DATA SETUP
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    struct Admin {
        bool isAdmin;
        bool isDev;
        bytes32 name;
    }
    mapping (address => Admin) admins_;
    
    uint256 adminCount_;
    uint256 devCount_;
    uint256 requiredSignatures_;
    uint256 requiredDevSignatures_;
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // CONSTRUCTOR
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    constructor()
        public
    {
    
        admins_[DEV_1_ADDRESS] = Admin(true, true, DEV_1_NAME);
        
        adminCount_ = 1;
        devCount_ = 1;
        requiredSignatures_ = 1;
        requiredDevSignatures_ = 1;
    }
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // FALLBACK, SETUP, AND FORWARD
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // there should never be a balance in this contract.  but if someone
    // does stupidly send eth here for some reason.  we can forward it 
    // to jekyll island
    function ()
        public
        payable
    {
        FundForwarder.deposit.value(address(this).balance)();
    }
    
    function setup(address _addr)
        onlyDevs()
        public
    {
        require( address(FundForwarder) == address(0) );
        FundForwarder = FundForwarderInterface(_addr);
    }    
    
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // MODIFIERS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    modifier onlyDevs()
    {
        require(admins_[msg.sender].isDev == true, "onlyDevs failed - msg.sender is not a dev");
        _;
    }
    
    modifier onlyAdmins()
    {
        require(admins_[msg.sender].isAdmin == true, "onlyAdmins failed - msg.sender is not an admin");
        _;
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // DEV ONLY FUNCTIONS
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    /**
    * @dev DEV - use this to add admins.  this is a dev only function.
    * @param _who - address of the admin you wish to add
    * @param _name - admins name
    * @param _isDev - is this admin also a dev?
    */
    function addAdmin(address _who, bytes32 _name, bool _isDev)
        public
        onlyDevs()
    {
        if (MSFun.multiSig(msData, requiredDevSignatures_, "addAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "addAdmin");
            
            // must check this so we dont mess up admin count by adding someone
            // who is already an admin
            if (admins_[_who].isAdmin == false) 
            { 
                
                // set admins flag to true in admin mapping
                admins_[_who].isAdmin = true;
        
                // adjust admin count and required signatures
                adminCount_ += 1;
                requiredSignatures_ += 1;
            }
            
            // are we setting them as a dev?
            // by putting this outside the above if statement, we can upgrade existing
            // admins to devs.
            if (_isDev == true) 
            {
                // bestow the honored dev status
                admins_[_who].isDev = _isDev;
                
                // increase dev count and required dev signatures
                devCount_ += 1;
                requiredDevSignatures_ += 1;
            }
        }
        
        // by putting this outside the above multisig, we can allow easy name changes
        // without having to bother with multisig.  this will still create a proposal though
        // so use the deleteAnyProposal to delete it if you want to
        admins_[_who].name = _name;
    }

    /**
    * @dev DEV - use this to remove admins. this is a dev only function.
    * -requirements: never less than 1 admin
    *                never less than 1 dev
    *                never less admins than required signatures
    *                never less devs than required dev signatures
    * @param _who - address of the admin you wish to remove
    */
    function removeAdmin(address _who)
        public
        onlyDevs()
    {
        // we can put our requires outside the multisig, this will prevent
        // creating a proposal that would never pass checks anyway.
        require(adminCount_ > 1, "removeAdmin failed - cannot have less than 2 admins");
        require(adminCount_ >= requiredSignatures_, "removeAdmin failed - cannot have less admins than number of required signatures");
        if (admins_[_who].isDev == true)
        {
            require(devCount_ > 1, "removeAdmin failed - cannot have less than 2 devs");
            require(devCount_ >= requiredDevSignatures_, "removeAdmin failed - cannot have less devs than number of required dev signatures");
        }
        
        // checks passed
        if (MSFun.multiSig(msData, requiredDevSignatures_, "removeAdmin") == true) 
        {
            MSFun.deleteProposal(msData, "removeAdmin");
            
            // must check this so we dont mess up admin count by removing someone
            // who wasnt an admin to start with
            if (admins_[_who].isAdmin == true) {  
                
                //set admins flag to false in admin mapping
                admins_[_who].isAdmin = false;
                
                //adjust admin count and required signatures
                adminCount_ -= 1;
                if (requiredSignatures_ > 1) 
                {
                    requiredSignatures_ -= 1;
                }
            }
            
            // were they also a dev?
            if (admins_[_who].isDev == true) {
                
                //set dev flag to false
                admins_[_who].isDev = false;
                
                //adjust dev count and required dev signatures
                devCount_ -= 1;
                if (requiredDevSignatures_ > 1) 
                {
                    requiredDevSignatures_ -= 1;
                }
            }
        }
    }

    /**
    * @dev DEV - change the number of required signatures.  must be between
    * 1 and the number of admins.  this is a dev only function
    * @param _howMany - desired number of required signatures
    */
    function changeRequiredSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
        // make sure its between 1 and number of admins
        require(_howMany > 0 && _howMany <= adminCount_, "changeRequiredSignatures failed - must be between 1 and number of admins");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredSignatures");
            
            // store new setting.
            requiredSignatures_ = _howMany;
        }
    }
    
    /**
    * @dev DEV - change the number of required dev signatures.  must be between
    * 1 and the number of devs.  this is a dev only function
    * @param _howMany - desired number of required dev signatures
    */
    function changeRequiredDevSignatures(uint256 _howMany)
        public
        onlyDevs()
    {  
        // make sure its between 1 and number of admins
        require(_howMany > 0 && _howMany <= devCount_, "changeRequiredDevSignatures failed - must be between 1 and number of devs");
        
        if (MSFun.multiSig(msData, requiredDevSignatures_, "changeRequiredDevSignatures") == true) 
        {
            MSFun.deleteProposal(msData, "changeRequiredDevSignatures");
            
            // store new setting.
            requiredDevSignatures_ = _howMany;
        }
    }

    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // EXTERNAL FUNCTIONS 
    //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    function requiredSignatures() external view returns(uint256) {return(requiredSignatures_);}
    function requiredDevSignatures() external view returns(uint256) {return(requiredDevSignatures_);}
    function adminCount() external view returns(uint256) {return(adminCount_);}
    function devCount() external view returns(uint256) {return(devCount_);}
    function adminName(address _who) external view returns(bytes32) {return(admins_[_who].name);}
    function isAdmin(address _who) external view returns(bool) {return(admins_[_who].isAdmin);}
    function isDev(address _who) external view returns(bool) {return(admins_[_who].isDev);}
}