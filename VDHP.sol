// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

contract dhp {
    
    address addressVaccine;
    address addressLocationInfo;
    
    bool signIn = false;
    string signedAs;
    
    //Issuer Structure
    struct issuer {
        uint256 iID;
        string iName;
        string qualification;
        string photoUrl;
        string ilocation;
        string iPassword;
        mapping(uint256 => bool) iSignUp;
    }
    
    //Holder Structure
    struct holder{
        uint256 hID;
        string hName;
        bytes32 age;
        string photoUrl;
        string hlocation;
        string hEmail;
        string hPassword;
        uint256 testResult;
        bool vaccineTaken;
        string vName;
        uint256 doseNo;
        string issuedBy;
        uint256 priority;
        uint256 pAge;
        uint256 phLocation;
        mapping(uint256 => bool) hSignUp;
        mapping(uint256 => bool) resultedMap;
    }
    
    issuer[] private issuers;
    holder[] private holders;
    
    
    mapping(address => issuer) private iAdd;
    mapping(address => holder) private hAdd;
    
    event issuerSignedUp(uint256 _id1);
    event holderSignedUp(uint256 _id2);
    event providerSignedUp(uint256 _id3);
    event authoritySignedUp(uint256 _id4);
    event vaccineStored(uint256 _id5);
    
    //set Vaccination contract's address
    function setContractVaccination(address _addr) external {
        addressVaccine = _addr;
    }
    
    //set LocationInfo contract's address
    function setContractLocation(address _addr) external {
        addressLocationInfo = _addr;
    }
    
    function hChecker(address addr) public view returns(uint256){
        uint256 h=0;
        
        while(h<holders.length)
        {
            if(hAdd[addr].hSignUp[h] == true)
            {
                break;
            }
            h++;
        }
        
        return(
            h
        );
    }
    
    function iChecker(address addr) public view returns(uint256){
        uint256 i=0;
        
        while(i<issuers.length)
        {
            if(iAdd[addr].iSignUp[i] == true)
            {
                break;
            }
            i++;
        }
        
        return(
            i
        );
    }
    
    function aChecker(address addr) public view returns(uint256){
        vaccination v = vaccination(addressVaccine);
        uint256 a=0;
        
        while(a<v.getAuthorityLen())
        {
            if(v.getAsignUp(a, addr) == true)
            {
                break;
            }
            a++;
        }
        
        return(
            a
        );
    }
    
    function pChecker(address addr) public view returns(uint256){
        vaccination v = vaccination(addressVaccine);
        uint256 p=0;
        
        while(p<v.getVPLen())
        {
            if(v.getVPsignUp(p, addr) == true)
            {
                break;
            }
            p++;
        }
        
        return(
            p
        );
    }
    
    //Issuer Sign-Up (Goes to the issuer interface)
    function iSignUp(string memory _iName, string memory _qualification, string memory _photoUrl, string memory _ilocation, string memory _iPassword) public {
        
        vaccination v = vaccination(addressVaccine);
        
        uint256 h = hChecker(msg.sender);
        uint256 i = iChecker(msg.sender);
        uint256 a = aChecker(msg.sender);
        uint256 p = pChecker(msg.sender);
        
        require(bytes(_iName).length > 0, "Issuer's name must not be kept empty");
        require(bytes(_qualification).length > 0, "Issuer's qualification must not be kept empty");
        require(bytes(_photoUrl).length > 0, "Issuer's photo must not be kept empty");
        require(bytes(_ilocation).length > 0, "Issuer's location must not be kept empty");
        require(iAdd[msg.sender].iSignUp[i] == false, "This Issuer account already exists.");
        require(hAdd[msg.sender].hSignUp[h] == false, "This account belongs to a Holder.");
        require(v.getVPsignUp(p,msg.sender) == false, "This account belongs to a Vaccine Provider.");
        require(v.getAsignUp(a,msg.sender) == false, "This account belongs to an Authority.");

        uint256 id1 = issuers.length;
        
        issuer memory newIssuer = issuer({
            iID: id1,
            iName: _iName,
            qualification: _qualification,
            photoUrl: _photoUrl,
            ilocation: _ilocation,
            iPassword: _iPassword
        });
        
        issuers.push(newIssuer);
        emit issuerSignedUp(id1);
        iAdd[msg.sender].iSignUp[id1] = true;
    }
    
    //Sign-In (Goes to the general interface)
    function SignIn(uint256 _ID, string memory _password, address addr) public returns (bool, string memory) {
        
        vaccination v = vaccination(addressVaccine);
        
        signIn=false;
        signedAs="None";
        
        if (iAdd[addr].iSignUp[_ID] == true)
        {
            require(keccak256(abi.encodePacked((issuers[_ID].iPassword))) == keccak256(abi.encodePacked((_password))), "Incorrect Password...!!!");
            signIn=true;
            signedAs = "issuer";
            return
            (
                signIn,
                signedAs
            );
        }
        
        else if (hAdd[addr].hSignUp[_ID] == true)
        {
            require(keccak256(abi.encodePacked((holders[_ID].hPassword))) == keccak256(abi.encodePacked((_password))), "Incorrect Password...!!!");
            signIn=true;
            signedAs = "holder";
            return
            (
                signIn,
                signedAs
            );
        }
        
        else if (v.getVPsignUp(_ID, addr) == true)
        {
            require(keccak256(abi.encodePacked((v.getVPpassword(_ID)))) == keccak256(abi.encodePacked((_password))), "Incorrect Password...!!!");
            signIn=true;
            signedAs = "vaccineProvider";
            return
            (
                signIn,
                signedAs
            );
        }
        
        else if (v.getAsignUp(_ID, addr) == true)
        {
            require(keccak256(abi.encodePacked((v.getApassword(_ID)))) == keccak256(abi.encodePacked((_password))), "Incorrect Password...!!!");
            signIn=true;
            signedAs = "authority";
            return
            (
                signIn,
                signedAs
            );
        }
        
        else
        {
            require(signIn == true, "Sign IN Failed...!!!");
            
            return
            (
                signIn,
                signedAs
            );
            
        }
        
    }
    
    //Issuer issues the test result (Goes to the issuer interface)
    function issueResult(uint256 _id2, uint256 _testResult) public {
        
        locationInfo l = locationInfo(addressLocationInfo);
        
        uint256 _iID = iChecker(msg.sender);
        require(_iID < issuers.length && _iID >= 0, "No Issuer found");
        
        require(_id2 < holders.length, "Holder does not exist");
        require(_testResult == 0 || _testResult == 1, "Invalid Result");
        //require(iAdd[addr].iSignUp[_iID] == true, "You are not an Issuer.");

        holders[_id2].testResult = _testResult ;
        
        l.setTotalTests(holders[_id2].hlocation);
        
        if(_testResult==1){
            l.setTotalPositives(holders[_id2].hlocation);
        }
        
        holders[_id2].issuedBy = issuers[_iID].iName;
        
        holders[_id2].resultedMap[_id2] = true;
        
    }
    
    //Holder views his/her test result (Goes to the holder interface)
    function getMyResult(address addr) public view returns(uint256, string memory) {
        
        uint256 _id2 = hChecker(addr);
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        require(holders[_id2].resultedMap[_id2] == true, "This holder has not tested yet.");
        //require(hAdd[addr].hSignUp[_id2] == true, "This account does not belongs to you.");
        
        return (
            holders[_id2].testResult,
            holders[_id2].issuedBy
        );
    }
    
    
    //Converting uint256 to bytes32
    function convertBytes(uint256 _age) public pure returns (bytes32) {
        return bytes32(_age);
    }
    
    //Converting bytes32 to uint256
    function convertUint(bytes32 _age) public pure returns (uint256) {
        return uint256(_age);
    }
    
    //Holder Sign-Up (Goes to the holder interface)
    function hSignUp(string memory _hName, uint256 _age, string memory _photoUrl, string memory _hlocation, string memory _hEmail, string memory _password) public {
        
        vaccination v = vaccination(addressVaccine);
        
        uint256 h = hChecker(msg.sender);
        uint256 i = iChecker(msg.sender);
        uint256 a = aChecker(msg.sender);
        uint256 p = pChecker(msg.sender);
        
        require(bytes(_hName).length > 0, "Holder's name must not be kept empty");
        require(convertBytes(_age).length > 0, "Holder's age must not be kept empty");
        require(bytes(_photoUrl).length > 0, "Holder's photo must not be kept empty");
        require(bytes(_hlocation).length > 0, "Holder's location must not be kept empty");
        require(hAdd[msg.sender].hSignUp[h] == false, "This Holder account already exists.");
        require(iAdd[msg.sender].iSignUp[i] == false, "This account belongs to an Issuer.");
        require(v.getVPsignUp(p,msg.sender) == false, "This account belongs to a Vaccine Provider.");
        require(v.getAsignUp(a,msg.sender) == false, "This account belongs to an Authority.");

        uint256 id2 = holders.length;

        holder memory newHolder = holder({
            hID: id2,
            hName: _hName,
            age: convertBytes(_age),
            photoUrl: _photoUrl,
            hlocation: _hlocation,
            hEmail: _hEmail,
            hPassword: _password,
            testResult: 0,
            vaccineTaken: false,
            vName: "None",
            doseNo: 0,
            issuedBy: "None",
            priority: 0,
            pAge: 1,
            phLocation: 1
        });

        holders.push(newHolder);
        emit holderSignedUp(id2);
        hAdd[msg.sender].hSignUp[id2] = true;
    }
    
    //Holder specifies the attributes which should be publicly visible (Goes to the holder interface)
    function holderPermission(uint256 _pAge, uint256 _phLocation) public{
        uint256 _id2 = hChecker(msg.sender);
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        
        holders[_id2].pAge = _pAge;
        holders[_id2].phLocation = _phLocation;
    }
    
    //Getting the Age permission
    function getAgePermission(uint256 _id2) public view returns (uint256)
    {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return(
            holders[_id2].pAge
        );
    }
    
    //Getting the Location permission
    function getLocationPermission(uint256 _id2) public view returns (uint256)
    {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return(
            holders[_id2].phLocation
        );
    }
    
    //Verifier verifies holders DHP (Goes to the verifier interface)
    function verification(address addr) external view returns(string memory, uint256, string memory, string memory, uint256, string memory)
    {
        uint256 _id2 = hChecker(addr);
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        require(holders[_id2].resultedMap[_id2] == true, "This holder has not tested yet.");
        string memory perLocation = "Showing location is not permitted..!!!";
        
        uint256 _pAge = getAgePermission(_id2);
        uint256 _phLocation = getLocationPermission(_id2);
        
        
        if(_pAge == 0 && _phLocation == 0)
        {
                
            return(
                holders[_id2].hName,
                0,
                holders[_id2].photoUrl,
                perLocation,
                holders[_id2].testResult,
                holders[_id2].issuedBy
            );
        }
        else if(_pAge == 1 && _phLocation == 0)
        {
            return(
                holders[_id2].hName,
                convertUint(holders[_id2].age),
                holders[_id2].photoUrl,
                perLocation,
                holders[_id2].testResult,
                holders[_id2].issuedBy
            );
        }
        else if(_pAge == 0 && _phLocation == 1)
        {
            return (
                holders[_id2].hName,
                0,
                holders[_id2].photoUrl,
                holders[_id2].hlocation,
                holders[_id2].testResult,
                holders[_id2].issuedBy
            );
        }
        else
        {
            return (
                holders[_id2].hName,
                convertUint(holders[_id2].age),
                holders[_id2].photoUrl,
                holders[_id2].hlocation,
                holders[_id2].testResult,
                holders[_id2].issuedBy
            );
        }
    }
    
    //View Holder Profile (Goes to the holder interface)
    function getHolder(address addr) public view returns(string memory, string memory, uint256, uint256, string memory, string memory)
    {
        uint256 _id2 = hChecker(addr);
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        
        return (
            holders[_id2].photoUrl,
            holders[_id2].hName,
            holders[_id2].hID,
            convertUint(holders[_id2].age),
            holders[_id2].hlocation,
            holders[_id2].hEmail
        );
    }
    
    //View Issuer Profile (Goes to the issuer interface)
    function getIssuer(address addr) external view returns(string memory, string memory, uint256, string memory, string memory)
    {
        //require(iAdd[addr].iSignUp[_id1] == true, "This account does not belongs to you.");
        
        uint256 _id1 = iChecker(addr);
        require(_id1 < issuers.length && _id1 >= 0, "No Issuer found");
        
        return (
            issuers[_id1].photoUrl,
            issuers[_id1].iName,
            issuers[_id1].iID,
            issuers[_id1].qualification,
            issuers[_id1].ilocation
        );
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    function getResult(uint256 _id2) public view returns(uint256) {
        require(holders[_id2].resultedMap[_id2] == true, "This holder has not tested yet.");
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].testResult
        );
    }
    
    function getHLocation(uint256 _id2) public view returns(string memory) {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].hlocation
        );
    }
    
    function getResultedMap(uint256 _id2) public view returns(bool){
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].resultedMap[_id2]
        );
    }
    
    function getHname(uint256 _id2) public view returns(string memory){
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].hName
        );
    }
    
    function setHolderPriority(uint256 _id2, uint256 _priority) public {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        
        holders[_id2].priority = _priority;
        
    }
    
    function getHolderPriority(uint256 _id2) public view returns(uint256){
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].priority
        );
    }
    
    function setDoseNo(uint256 _id2, uint256 _doseNo) public {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");

            holders[_id2].doseNo += _doseNo;

    }
    
    function getDoseNo(uint256 _id2) public view returns(uint256){
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].doseNo
        );
    }
    
    function setVname(uint256 _id2, string memory _vName) public {
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
            holders[_id2].vName = _vName;
    }
    
    function getVname(uint256 _id2) public view returns(string memory){
        require(_id2 < holders.length && _id2 >= 0, "No Holder found");
        return (
            holders[_id2].vName
        );
    }
    
    function getTotalHolder() public view returns(uint256){
        require(holders.length>0, "Holder database is empty.");
        return (
            holders.length
        );
    }
    
    function getIsignUp(uint256 _id2, address _add) public view returns(bool){
        return (
            iAdd[_add].iSignUp[_id2]
        );
    }
    
    function getHsignUp(uint256 _id2, address _add) public view returns(bool){
        return (
            hAdd[_add].hSignUp[_id2]
        );
    }
    
    function getHolderLen() public view returns(uint256){
        return (
            holders.length
        );
    }
    
    function getHvaccineTaken(uint256 _hid) public view returns(bool){
        return (
            holders[_hid].vaccineTaken
        );
    }
    
    function setPushedVaccine(uint256 _hID) public{
        require(_hID < holders.length && _hID >= 0, "No Holder found");
        holders[_hID].vaccineTaken = true;
    }
    
    // View vaccine taken Information (Goes to Holder Interface)
    function getVaccinationInfo(address addr) public view returns(string memory, bool, string memory, uint256, uint256){
        uint256 _hID = hChecker(addr);
        require(_hID < holders.length && _hID >= 0, "No Holder found");
        
        return(
            holders[_hID].hName,
            holders[_hID].vaccineTaken,
            holders[_hID].vName,
            holders[_hID].doseNo,
            holders[_hID].priority
        );
    }
}
    
contract vaccination{
    
    address addressDhp;
    address addressLocationInfo;
    
    bool signIn=false;
    string signedAs;
        
    struct vaccineInfo{
        uint256 vID;
        string vName;
        uint256 vStorage;
        uint256 doseLimit;
        mapping (uint256 => bool) approved;
    }
    
    //centralAuthority
    struct authority{
        uint256 aID;
        string aName;
        string aPassword;
        string[] high;
        string[] low;
        mapping (uint256 => bool) aSignUp;
    }
    
    //vaccineProvider
    struct vaccineProvider{
        uint256 pID;
        string pName;
        string photoUrl;
        string plocation;
        string pPassword;
        mapping (uint256 => bool) pSignUp;
    }
    
    vaccineProvider[] private vProviders;
    authority[] private authorities;
    vaccineInfo[] private vaccines;
    
    mapping(address => vaccineProvider) private vpAdd;
    mapping(address => authority) private aAdd;
    
    event providerSignedUp(uint256 _id3);
    event authoritySignedUp(uint256 _id4);
    event vaccineStored(uint256 _id5);
    
    //set DHP contract's address
    function setContractDHP(address _addr) external {
        addressDhp = _addr;
    }
    
    //set LocationInfo contract's address
    function setContractLocation(address _addr) external {
        addressLocationInfo = _addr;
    }
    
    //Vaccine Provider Sign-Up (Goes to the Vaccine Provider interface)
    function pSignUp(string memory _pName, string memory _photoUrl, string memory _plocation, string memory _password) public {
        dhp c = dhp(addressDhp);
        uint256 h = c.hChecker(msg.sender);
        uint256 i = c.iChecker(msg.sender);
        uint256 a = c.aChecker(msg.sender);
        uint256 p = c.pChecker(msg.sender);
        
        require(bytes(_pName).length > 0, "Vaccine provider's name must not be kept empty");
        require(bytes(_photoUrl).length > 0, "Vaccine provider's photo must not be kept empty");
        require(bytes(_plocation).length > 0, "Vaccine provider's location must not be kept empty");
        require(vpAdd[msg.sender].pSignUp[p] == false, "This Vaccine Provider account already exists.");
        require(c.getIsignUp(i,msg.sender) == false, "This account belongs to an issuer.");
        require(c.getHsignUp(h,msg.sender) == false, "This account belongs to a Holder.");
        require(aAdd[msg.sender].aSignUp[a] == false, "This account belongs to a Authority");

        uint256 id3 = vProviders.length;
        
        vaccineProvider memory newVprovider = vaccineProvider({
            pID: id3,
            pName: _pName,
            photoUrl: _photoUrl,
            plocation: _plocation,
            pPassword: _password
        });
        
        vProviders.push(newVprovider);
        emit providerSignedUp(id3);
        vpAdd[msg.sender].pSignUp[id3] = true;
    }
    
    //Authority Sign Up (Goes to the Authority interface)
    function aSignUp(string memory _aName, string memory _password) public {
        dhp c = dhp(addressDhp);
        uint256 h = c.hChecker(msg.sender);
        uint256 i = c.iChecker(msg.sender);
        uint256 a = c.aChecker(msg.sender);
        uint256 p = c.pChecker(msg.sender);
        
        require(bytes(_aName).length > 0, "Authority's name must not be kept empty");
        require(aAdd[msg.sender].aSignUp[a] == false, "This Authority account already exists.");
        require(c.getIsignUp(i,msg.sender) == false, "This account belongs to an issuer.");
        require(c.getHsignUp(h,msg.sender) == false, "This account belongs to a Holder.");
        require(vpAdd[msg.sender].pSignUp[p] == false, "This account belongs to a Vaccine Provider.");

        uint256 id4 = vProviders.length;
        
        authority memory newAuthority = authority({
            aID: id4,
            aName: _aName,
            aPassword: _password,
            high: new string[](authorities.length),
            low: new string[](authorities.length)
        });
        
        authorities.push(newAuthority);
        emit authoritySignedUp(id4);
        aAdd[msg.sender].aSignUp[id4] = true;
    }
    
    //Set Priority (Goes to the Authority interface)
    function setPriority() public {
        dhp c = dhp(addressDhp);
        locationInfo l = locationInfo(addressLocationInfo);
        
        l.setRatio();
        
        uint256 _aID = c.aChecker(msg.sender);
        require(_aID < authorities.length && _aID >= 0, "No Authority found");
        require(aAdd[msg.sender].aSignUp[_aID] == true, "You are not a authority or this account does not belongs to you.");
        
        uint256 htotal = c.getHolderLen();
        uint256 hid=0;
        uint256 j=8;
        uint256 k=0;
        
        //for checking different locations
        while(j<16)
        {
            hid=0;
            if(l.getTotalTests(k)>1)
            {
                //for checking different holders
                while (hid<htotal)
                {
                    if(c.getResult(hid) == 1 && keccak256(abi.encodePacked((l.getLocationPriority(k)))) == keccak256(abi.encodePacked((c.getHLocation(hid)))) && c.getHvaccineTaken(hid) == false)
                    {
                        authorities[_aID].low.push(c.getHname(hid));
                        l.setLowNo(k,1);
                        l.setCompLow(k,1);
                        c.setHolderPriority(hid,j);
                    }
                    
                    else if(c.getResult(hid) == 0 && c.getResultedMap(hid) == true && keccak256(abi.encodePacked((l.getLocationPriority(k)))) == keccak256(abi.encodePacked((c.getHLocation(hid)))) && c.getHvaccineTaken(hid) == false)
                    {
                        authorities[_aID].high.push(c.getHname(hid));
                        l.setHighNo(k,1);
                        l.setCompHigh(k,1);
                        c.setHolderPriority(hid,k);
                    }
                    
                    hid++;
                }
                j++;
                k++;
            }
            
            else
            {
                break;
            }
        }
    }
    
    //View Priority (Goes to the Vaccine Provider interface)
    function getPriority(uint256 _aID) external view returns(string[] memory, string[] memory)
    {
        require(_aID < authorities.length && _aID >= 0, "No authority found");
        
        return (
            authorities[_aID].high,
            authorities[_aID].low
        );
    }
    
    //Vaccine storage (Goes to the Authority interface)
    function setVaccine(string memory _vName, uint256 _vStorage, uint256 _doseLimit) public {
        
        dhp c = dhp(addressDhp);
        
        uint256 _aID = c.aChecker(msg.sender);
        require(_aID < authorities.length && _aID >= 0, "No Authority found");
        require(aAdd[msg.sender].aSignUp[_aID] == true, "You are not a authority or this account does not belongs to you.");
        require(bytes(_vName).length > 0, "Vaccine's name must not be kept empty");
        require(c.convertBytes(_vStorage).length > 0, "Vaccine's storage must not be kept empty");
        require(c.convertBytes(_doseLimit).length > 0, "Dose limit must not be kept empty");
        
        uint256 id5 = vaccines.length;
        
        vaccineInfo memory newVaccine = vaccineInfo({
            vID: id5,
            vName: _vName,
            vStorage: _vStorage,
            doseLimit: _doseLimit
        });
        
        vaccines.push(newVaccine);
        emit vaccineStored(id5);
        vaccines[id5].approved[id5] = true;
    }
    
    //Update vaccine storage (Goes to the Authority interface)
    function updateStorage(uint256 _vID, uint256 _vStorage) public {
        dhp c = dhp(addressDhp);
        uint256 _aID = c.aChecker(msg.sender);
        require(_aID < authorities.length && _aID >= 0, "No Authority found");
        require(aAdd[msg.sender].aSignUp[_aID] == true, "You are not a authority or this account does not belongs to you.");
        require(c.convertBytes(_vStorage).length > 0, "Vaccine's storage must not be kept empty");
        vaccines[_vID].vStorage += _vStorage;
    }
    
    //Push Vaccine (Goes to the Vaccine Provider interface)
    function pushVaccine(uint256 _aID, uint256 _vID, uint256 _hID, string memory _vName) public {
        
        dhp c = dhp(addressDhp);
        locationInfo l = locationInfo(addressLocationInfo);
        
        uint256 _pID = c.pChecker(msg.sender);
        require(_pID < vProviders.length && _pID >= 0, "No Vaccine Provider found");
        
        require(_hID < c.getTotalHolder(), "Holder does not exist");
        require(c.getResultedMap(_hID) == true, "This holder has not tested yet.");
        require(vaccines[_vID].approved[_vID] == true, "This vaccine has no approval.");
        require(vaccines[_vID].vStorage > 0, "This vaccine is out of stock.");
        require(c.getDoseNo(_hID) < vaccines[_vID].doseLimit, "Vaccination dose is already completed");
        require(vpAdd[msg.sender].pSignUp[_pID] == true, "You are not a vaccine provider or this account does not belongs to you.");
        require(keccak256(abi.encodePacked((vaccines[_vID].vName))) == keccak256(abi.encodePacked((_vName))), "This vaccine does not exist.");
        
        uint256 j=0;
        uint256 i=0;
        uint256 n=0;
        uint256 k=0;
        
        while (j<8)
        {
            if(l.getHighNo(j)!=0)
            {
                break;
            }
            j++;
        }
        
        if(j<8)
        {
            require(c.getHolderPriority(_hID) == j, "Vaccination is not completed for the higher priority Holders yet.");

            c.setVname(_hID,_vName);
            vaccines[_vID].vStorage -= 1;
            c.setDoseNo(_hID,1);
            c.setPushedVaccine(_hID);
            l.minHighNo(j,1);
        }
        
        else if(j>=8)
        {
            while (j<16)
            {
                if(l.getLowNo(k)!=0)
                {
                    break;
                }
                k++;
                j++;
            }
            
            if(j<16)
            {
                require(c.getHolderPriority(_hID) == j, "Vaccination is not completed for the higher priority Holders yet.");
                c.setVname(_hID,_vName);
                vaccines[_vID].vStorage -= 1;
                c.setDoseNo(_hID,1);
                c.setPushedVaccine(_hID);
                l.minLowNo(k,1);
            }
            
            else if(j>=16)
            {
                k=0;
                while (k<8) 
                {
                    if(l.getCompHigh(k)!=0)
                    {
                        break;
                    }
                    k++;
                }
            
                if(k<8)
                {
                    require(c.getHolderPriority(_hID) == k, "Vaccination is not completed for the higher priority Holders yet.");
        
                    c.setVname(_hID,_vName);
                    vaccines[_vID].vStorage -= 1;
                    c.setDoseNo(_hID,1);
                    c.setPushedVaccine(_hID);
                    l.minCompHigh(k,1);
                    
                    if (c.getDoseNo(_hID) == vaccines[_vID].doseLimit)
                    {
                        uint256 htotal=authorities[_aID].high.length;
                        
                        while(i<=htotal)
                        {
                            if(keccak256(abi.encodePacked((authorities[_aID].high[i]))) == keccak256(abi.encodePacked((c.getHname(_hID)))))
                            {
                                break;
                            }
                            n += 1;
                            i++;
                        }
                        authorities[_aID].high[n] = authorities[_aID].high[authorities[_aID].high.length - 1];
                        delete authorities[_aID].high[authorities[_aID].high.length - 1];
                    }
                }
                
                else if(k>=8)
                {
                    j=0;
                    while (k<16)
                    {
                        if(l.getCompLow(j)!=0)
                        {
                            break;
                        }
                        j++;
                        k++;
                    }
                    
                    if(k<16)
                    {
                        require(c.getHolderPriority(_hID) == k, "Vaccination is not completed for the higher priority Holders yet.");
                        c.setVname(_hID,_vName);
                        vaccines[_vID].vStorage -= 1;
                        c.setDoseNo(_hID,1);
                        c.setPushedVaccine(_hID);
                        l.minCompLow(j,1);
                        
                        if (c.getDoseNo(_hID) == vaccines[_vID].doseLimit)
                        {
                            uint256 ltotal=authorities[_aID].low.length;    
                        
                            while(i<=ltotal)
                            {
                                if(keccak256(abi.encodePacked((authorities[_aID].low[i]))) == keccak256(abi.encodePacked((c.getHname(_hID)))))
                                {
                                    break;
                                }
                                n += 1;
                                i++;
                            }
                            authorities[_aID].low[n] = authorities[_aID].low[authorities[_aID].low.length - 1];
                            delete authorities[_aID].low[authorities[_aID].low.length - 1];
                        }
                    }
                }   
            }
        }
    }
    
    //View Vaccine Provider Profile (Goes to the vaccine provider interface)
    function getVaccineProvider(address addr) external view returns(string memory, string memory, uint256, string memory)
    {
        dhp c = dhp(addressDhp);
        uint256 _id3 = c.pChecker(addr);
        require(_id3 < vProviders.length && _id3 >= 0, "No Vaccine Provider found");
        require(vpAdd[addr].pSignUp[_id3] == true, "This account does not belongs to you.");
        
        
        return (
            vProviders[_id3].photoUrl,
            vProviders[_id3].pName,
            vProviders[_id3].pID,
            vProviders[_id3].plocation
        );
    }
    
    function getVPpassword(uint256 ID) external view returns(string memory)
    {
        return(
            vProviders[ID].pPassword
        );
    }
    
    //View Authority Profile (Goes to the authority interface)
    function getAuthority(address addr) external view returns(string memory, uint256)
    {
        dhp c = dhp(addressDhp);
        uint256 _id4 = c.aChecker(addr);
        require(_id4 < authorities.length && _id4 >= 0, "No Authority found");
        require(aAdd[addr].aSignUp[_id4] == true, "This account does not belongs to you.");
        
        
        return (
            authorities[_id4].aName,
            authorities[_id4].aID
        );
    }
    
    function getApassword(uint256 ID) external view returns(string memory)
    {
        return(
            authorities[ID].aPassword
        );
    }
    
    // View Vaccine Info (Goes to all interface)
    function getVaccine(uint256 _vID) public view returns(uint256, string memory, uint256, uint256)
    {
        require(vaccines[_vID].approved[_vID] == true, "This vaccine has no approval.");
        
        return(
            vaccines[_vID].vID,
            vaccines[_vID].vName,
            vaccines[_vID].vStorage,
            vaccines[_vID].doseLimit
        );
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    
    function getVPsignUp(uint256 _id2, address _add) public view returns(bool){
        return (
            vpAdd[_add].pSignUp[_id2]
        );
    }
    
    function getAsignUp(uint256 _id2, address _add) public view returns(bool){
        return (
            aAdd[_add].aSignUp[_id2]
        );
    }
    
    function getVPLen() public view returns(uint256){
        return (
            vProviders.length
        );
    }
    
    function getAuthorityLen() public view returns(uint256){
        return (
            authorities.length
        );
    }
}

contract locationInfo{
    
    address addressDhp;
    address addressVaccine;
    
    string[] location;
    uint256[] totalTests;
    uint256[] totalPositives;
    uint256[] ratio;
    uint256[] highNO;
    uint256[] lowNO;
    string[] tempLoc;
    uint256[] tempT;
    uint256[] tempP;
    uint256[] tempRatio;
    uint256[] completedHigh;
    uint256[] completedLow;
    
    
    //set Vaccination contract's address
    function setContractVaccination(address _addr) external {
        addressVaccine = _addr;
    }
    
    //set DHP contract's address
    function setContractDHP(address _addr) external {
        addressDhp = _addr;
    }
    
    //setLocationInfo
    function setlocation() public {
        
        /*location = ["Barguna", "Barisal", "Bhola", "Jhalokati", "Patuakhali", "Pirojpur", "Bandarban", "Brahmanbaria",
        "Chandpur", "Chittagong", "Comilla", "Cox's Bazar", "Feni", "Khagrachari", "Lakshmipur", "Noakhali", "Rangamati",
        "Dhaka", "Faridpur", "Gazipur", "Gopalganj", "Kishoreganj", "Madaripur", "Manikganj", "Munshiganj", "Narayanganj",
        "Narsingdi", "Rajbari", "Shariatpur", "Tangail", "Bagerhat", "Chuadanga", "Jessore", "Jhenaidah","Khulna",
        "Kushtia", "Magura", "Meherpur", "Narail", "Satkhira", "Jamalpur", "Mymensingh", "Netrokona", "Sherpur", "Bogra",
        "Jaipurhat", "Naogaon", "Natore", "Nawabganj", "Pabna", "Rajshahi", "Sirajganj", "Dinajpur", "Gaibandha", "Kurigram",
        "Lalmonirhat", "Nilphamari", "Panchagarh", "Rangpur", "Thakurgaon", "Habiganj", "Moulvibazar", "Sunamganj", "Sylhet"];*/
        
        location = ["Dhaka", "Khulna", "Barisal", "Rajshahi", "Chittagong", "Sylhet", "Rangpur", "Mymensingh"];
        
        uint256 j=0;
        
        while(j<8){
            totalTests.push(1);
            totalPositives.push(0);
            highNO.push(0);
            lowNO.push(0);
            completedHigh.push(0);
            completedLow.push(0);
            ratio.push(1);
            j++;
        }
        
    }
    
    function getLocationInfo(string memory _location) public view returns(string memory,  uint256, uint256, uint256){
        
        uint256 j=0;
        
        while(j<8){
            if(keccak256(abi.encodePacked((location[j]))) == keccak256(abi.encodePacked((_location)))){
                break;
            }
            j++;
        }
        
        return (
            location[j],
            totalTests[j],
            totalPositives[j],
            ratio[j]
        );
    }
    
    function setCompHigh(uint256 index, uint256 num) public {
        completedHigh[index] = completedHigh[index] + num;
    }
    
    function minCompHigh(uint256 index, uint256 num) public {
        completedHigh[index] = completedHigh[index] - num;
    }
    
    function getCompHigh(uint256 index) public view returns(uint256){
        return(
            completedHigh[index]
        );
    }
    
    function setCompLow(uint256 index, uint256 num) public {
        completedLow[index] = completedLow[index] + num;
    }
    
    function minCompLow(uint256 index, uint256 num) public {
        completedLow[index] = completedLow[index] - num;
    }
    
    function getCompLow(uint256 index) public view returns(uint256){
        return(
            completedLow[index]
        );
    }
    
    function setHighNo(uint256 index, uint256 num) public {
        highNO[index] = highNO[index] + num;
    }
    
    function minHighNo(uint256 index, uint256 num) public {
        highNO[index] = highNO[index] - num;
    }
    
    function getHighNo(uint256 index) public view returns(uint256){
        return(
            highNO[index]
        );
    }
    
    function setLowNo(uint256 index, uint256 num) public {
        lowNO[index] = lowNO[index] + num;
    }
    
    function minLowNo(uint256 index, uint256 num) public {
        lowNO[index] = lowNO[index] - num;
    }
    
    function getLowNo(uint256 index) public view returns(uint256){
        return(
            lowNO[index]
        );
    }
    
    function setTotalTests(string memory _location) public {
        uint256 j=0;
        
        while(j<8){
            if(keccak256(abi.encodePacked((location[j]))) == keccak256(abi.encodePacked((_location)))){
                break;
            }
            j++;
        }
        
        totalTests[j] = totalTests[j] + 1;
    }
    
    function setTotalPositives(string memory _location) public {
        uint256 j=0;
        
        while(j<8){
            if(keccak256(abi.encodePacked((location[j]))) == keccak256(abi.encodePacked((_location)))){
                break;
            }
            j++;
        }
        
        totalPositives[j] = totalPositives[j] + 1;
    }
    
    function getTotalTests(uint256 index) public view returns(uint256){
        
        return (
            totalTests[index]
        );
    }
    
    function getTotalPositives(uint256 index) public view returns(uint256){
        
        return (
            totalPositives[index]
        );
    }
    
    function setRatio() public {
        uint256 j=0;
        
        while(j<8)
        {
            ratio[j]=percent(totalPositives[j],totalTests[j],4);
            highNO[j]=0;
            lowNO[j]=0;
            j++;
        }
        
        location = sortLocation(ratio, location, totalTests, totalPositives);
        totalTests = sortTotalTests(ratio, location, totalTests, totalPositives);
        totalPositives = sortTotalPositives(ratio, location, totalTests, totalPositives);
        ratio = sortRatio(ratio, location, totalTests, totalPositives);
        
        uint256 i=7;
        j=0;
        
        while(j<8)
        {
            tempRatio.push(ratio[i]);
            tempLoc.push(location[i]);
            tempT.push(totalTests[i]);
            tempP.push(totalPositives[i]);
            i--;
            j++;
        }
        
        ratio=tempRatio;
        location=tempLoc;
        totalTests=tempT;
        totalPositives=tempP;
    }
    
    function sortRatio(uint[] memory data, string[] memory _location, uint[] memory tTest, uint[] memory tPositive) public pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1), _location, tTest, tPositive);
        return (
            data
        );
    }
    
    function sortTotalTests(uint[] memory data, string[] memory _location, uint[] memory tTest, uint[] memory tPositive) public pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1), _location, tTest, tPositive);
            return (
            tTest
        );
    }
    
    function sortTotalPositives(uint[] memory data, string[] memory _location, uint[] memory tTest, uint[] memory tPositive) public pure returns (uint[] memory) {
        quickSort(data, int(0), int(data.length - 1), _location, tTest, tPositive);
        return (
            tPositive
        );
    }
    
    function sortLocation(uint[] memory data, string[] memory _location, uint[] memory tTest, uint[] memory tPositive) public pure returns (string[] memory) {
        quickSort(data, int(0), int(data.length - 1), _location, tTest, tPositive);
        return (
            _location
        );
    }
    
    function quickSort(uint[] memory arr, int left, int right, string[] memory loc, uint[] memory tt, uint[] memory tp) public pure {
    int i = left;
    int j = right;
    if (i == j) return;
    uint pivot = arr[uint(left + (right - left) / 2)];
    while (i <= j) {
        while (arr[uint(i)] < pivot) i++;
        while (pivot < arr[uint(j)]) j--;
        if (i <= j) {
            (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
            (loc[uint(i)], loc[uint(j)]) = (loc[uint(j)], loc[uint(i)]);
            (tt[uint(i)], tt[uint(j)]) = (tt[uint(j)], tt[uint(i)]);
            (tp[uint(i)], tp[uint(j)]) = (tp[uint(j)], tp[uint(i)]);
            i++;
            j--;
        }
    }
    if (left < j)
        quickSort(arr, left, j, loc, tt, tp);
    if (i < right)
        quickSort(arr, i, right, loc, tt, tp);
}
    
    function percent(uint256 numerator, uint256 denominator, uint256 precision) public pure returns(uint256) {

         // caution, check safe-to-multiply here
        uint256 _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint256 _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
  }
    
    function getLocationPriority(uint256 index) public view returns(string memory){
        return (
            location[index]
        );
    }
    
    function getRatio() public view returns(uint256[] memory)
    {
        return (
            ratio
        );
    }
    
    function getSortedLocation() public view returns(string[] memory){
        return (
            location
        );
    }
    
    function redZoneList(uint256 index) public view returns(string memory, uint256)
    {
            return(
                location[index],
                ratio[index]
            );
    }
}