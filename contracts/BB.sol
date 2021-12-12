//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// oooooooooooooooooooooooooooooooooooooooooooooooooooooooododddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooooooooooooooooooddddddddddddddddddddddddddddddddddddddooooooooooooooooooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooooooooooooooodooddddddddddddddddddddddddddddddddddddddoodoooooooooooooooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooooooooododdddddddddddddddddddddddddddddddddddddddddddddoodooooooooooooooooooooooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooooooooooooooooddddddddddddddddddddddddddddddddddddddddddddddddddoooooooooooooooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooooooooodddddddddddddddoolc::;;;;;;;;;;:::cccccccloooddddddooddooooooooooooooooooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooooooooooooddddddddddddddol:;;::::ccllloollcccc::;;;;;;::cc:::::ccoooddodoooooooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooododdddddddddoc;,;:coxO0KKKKKKKKKKKKXXKKK0Okxddoooollollc::;;;:clodoooooooooooooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooooooooodddddddddoc;,;:cdxOkkxxxxxxxxxxxxxxkkOKKKXKKK000OOkxddxxxxxxdlc:;;;:loooooooooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooooooooddddddl:,,;coxkkxdooollllllllllllllllodxkO0KKKK00OOOO00OOkkkkOOOkdl:;,;cooooooooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooooooodddddl:,,:lxkkxdooollllllcc:::;;;;;::ccllllodxk0KKKK00OOOOOOOOOOOOOOOOkdc,';loooooooooooooooooooooooooooooooooo
// oooooooooooooooooooooooooooooooooooodddddo:,,:oxOkxdoollll:;,,,;:::ccc::;,,'''''',:cllodkOKKKK0OOOOOOOOOOOOOOOOOko;';loooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooddddol;,;lk0kxoolllc:;,',;:loxkkOkkOOkkkkxxdol:;,'',;clodkOKKK00OOOOOOOOOOOOOOOOkl'':ooooooooooooooooooooooooooooooo
// ooooooooooooooooooooooooooooooooooodoc,,cx00kdllllc;,,;:ldkOOOOOOOOOkkkOkkkOkkkkkkkxoc;,',;codk0KKK0OOOOOOOOOOOOOOOOx;.;looooooooooooooooooooooooooooo
// looooooooooooooooooooooooooooooooooc,;lkK0kdlll:;,,:lxO0000OOOOOOOOOOkkkkkOOkkkkkkkOkkkxo:;,';coxOKKK0OOOOOOOOOOOkOOOx:.'looooooooooooooooooooooooooll
// llloooooooooooooooooooooooooooodoc;;oO00Odolc;'':ok000000000000000OOOOOOkOOOkkOkkkkkkkkkkkkdl;'':ldk0KK00OOOOOOOOkOOOOkc.'coooooooooooooooooooooooooll
// lloooooooooooooooooooooooooooodo;,lO00Oxdl:'.,lk0KKKKKKKKKKKKKKKKKK000OOOOOOkkkkkkkkkkkkkkkkOkdc,';lox0KKK0OOOOOOkOOOOOkl..cooooooooooooooooooooooooll
// looooooooooooooooooooooooooddol;:k00Okxo:'.,o0KKKKKKKXXXXXXXX00KXXKK0xooodoclxkkkkkkkkkkkkkkkkkkxc,';lok0KKK0OOOOOOOOOOOkl.'cooooooooooooooooooooooool
// looooooooooooooooooooooooooddc,cO0OOkdc'  :0X0dooodllOXKKK000l:dOKOxkd,..::',lxddxxxkkkkkkkkkkkkkkxc',cldk0KK0OOOOOOOOOOOkl.'loooooooooooooooooooooool
// ooooooooooooooooooooooooddddl,cO0OOOo,.  ;0NX0d,.':c:doodlc::;',cd::dl...;:;,:;,,;:;::c::cdkkkkkOkkko,':loxOKKK0OOOOOkOOOOkc.'ldoooooooooooooooooooooo
// oooooooooooooooooooooddddddd;;k000Oo'   .xNNX0l..,;;'ccoO;;:::'';c;lOd'..,:c;:;,,;:';::,',okkkkkkkkOkd,.;llok0KK0OOkOOOOOOOk:.,odooooooooooooooooooooo
// oooooooooooooooooooddddddddo,c0K0Od,.   :XNNNKo'.';coxooOxookkxxkkxk0kxkddk00KOdodl:oxd:,,lkkkOkkkkkkkd,.;llox0KKK0OOOOOOOOOx;.:oddooooooooooooooooooo
// oooooooooooooodddddddddddddl'lK0Okc'.  .xWNNN0xdxxk0XNXXXNNXNNNNNNNNXXXNNNNXNNNNNKOkkkkxddkkkOkkkkkkkkkd'.:llox0KKKOOOOOOOOOOd'.cdddddddoooooooooooooo
// oooooooodddddddddddddddddddl,l00Oo;'.  ;XWNNNKKXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXX0OOkkkkkkkkkkkkkkkkl..clloOKKK0OOOOOOOOOkl.,odddddddddddooooooooo
// ooddddddddddddddddddddddddxl'lOkd:''  .o0000OkkxxdddddddddddddddddddddoooddddddddxxxkkkxddxxkkkkkOOOOOkOx;.,llokKKK0OOOOOOOOOOk:.:ddddddddddddddddddoo
// dddddddddddddddddddxxdollllc:ldddodddxkOOO00Okkxxxkkkkxxxxxxxddoooooollcccccc::;;;;,,,;,,,,,,,,;;:::cllodc..clok0KK0OOOOOOOOOOOd''lxdddddddddddddddddd
// ddddddddddddxxxxxxxxxc';oxkO0KKKKKKKKKKK000000OOOOOOOOkkkkkkkkkxxxxxxxkkxxxxxxxdlcccccccccccc:::::;;;;,,'. .;lok0KK0OOOOOOOOOOOkl.;dxxxxxxxddddddddddd
// ddxxxxxxxxxxxxxxxxxxxl,;clllcoxxdddoccccllllcc:::::::::::;,,,,,,,,,,,,''''''.............................   ,lokKKK0OOOOOOOOOOOOx,'oxxxxxxxxxxxxxxxxdd
// xxxxxxxxxxxxxxxxxxxxkxxddddl':Oxccc.     ...... ...',....................... .  ...'::,....                 ,lokKKK0OOOOOOOOOOOOkl.cxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxkkkkkkkkkkkkkkkkd':0Ooll'     .......;cdkkxolc;......................;coxOOkxdoc'.               'ldOKKK0OOOOOOOOOOOOOd,,dkkkkkkxxxxxxxxxxx
// kkkkkkkkkkkkkkkkkkkkkkkkkkOx,;O0dll,     ....'cxkOOOOOOOkdc'..................,okOkOOkkkkkd:.               ,ldOKKKOOOOOOOOOOOOOOk;'okkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkkkkkkkkkOOOOOOOk;,k0xll;     ....lkOkkkOkxdddc,..................'oOOOkkOkxddo:..               ,lx0KKKOOOOOOOOOOOOOOk:.okkkkkkkkkkkkkkkkk
// kkkkkkkkkkkkOOOOOOOOOOOOOOOk:'xKxll;.    ...'lkOOkOOOkkxxl'...................ckOOOOOOOOkxl,.              .;okKKK0OOOOOOOOOOOOOOx;,dOOOOkkkkkkkkkkkkk
// OOOOOOOOOOOOOOOOOOOOOOOOOOOOl'oKOol:.    ....,oxxkO0OOOOOko,..................,lddxOOOkOOOOd,.             .cdOKKK0OOOOOOOOOOOOOOd,:kOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOOOOOOOOOO0d'c00dlc'    ...'cdxddkOkkOO0Oxc'................,oxkxxkOkkO00Ox:.             ,lx0KK0OOOOOOOOOOOOOOOo,lOOOOOOOOOOOOOOOOOO
// OOOOOOOOOOOOOOOOOOO000000000x,,OKxll,    ...ckOOOOO0O000Oko;.................cxOOOO00000Okdc'.            .:okKKK0OOOOOOOOOOOkOOk:,d0OOOOOOOOOOOOOOOOO
// OOOOOOOOOO000000000000000000O:.dKOol:.    ..':lodxOK0kxdoc,...................,:codOKOxol:,..             ,ld0KK0OOOOOOOOOOOOkOOd,:O00000000OOOOOOOOOO
// 00000000000000000000000000000o.c00xlc.    ......';okxc;''.........................'cdo:...               .cokKKK0OOOOOOOOOOOkkOkc,o0000000000000000000
// 0000000000000000KKKKKKKKK0000k,,kKkol;     ........,,'........................... ......                .:ld0KK0OOOOOOOOOOOOkOOd;:O0000000000000000000
// 00000OkxddxxkkkOKXNNNNXKK00000c'oKOxoc.     ...................................                        .:lokKKKOOOOOOkkOOOOOkOkc;d00000000000000000000
// 0000kdl:;,;;:clx0NNNNNKkxddO0Kx,:O0kdl;.              ....................                            .:lox0KK0OOOOOOOOOOOOOOOd:l000000000000000000000
// 000xollc;;;::cdkKXNNXKOkkkk0Okk:'d0Oxoc'                      ....''''.....                          .clldOKK0OOOOOOOOOOOOOOOkc:k000000000000000000000
// 00Oocclc;;;:cokkO0XXK0OkkkkOOxxl':O0kxoc.                    ...''''''''''...                      .,cllokKK0OOkOOOOOOOOOOOOko;o000000K000000000000000
// 00kollol;,;:coxxk0KK0kkxollxOkxd;.d0Okkdc.                   ..'''',;:::;,''..                    .;lllokKK0OOOOOOOOOOOOOOOOd;cOK0000K0000000000000000
// 00koclll::cooxOO0KXK0kddooodxxxxo.;OOOOkxl,.                 ....',,,,,;;,'...                  .,clllok0K0OOOOOOOOOOOOOOOOx::kKKKKKKK0000000000KKKKKK
// 000dlcllcldxooxk0XNN0kxddkxdk0kdd:.l0OkOOkxo;..                       .....                   .,clllldO00OOOOOOOOOOOOOOOOOkc,dKKKKKKKKKKK0000000KK00KK
// 00KOxlcllloooddxOOOkddx00kddxxk00d,,d0OOOOOkkdl;..                                          .,clllodk00OOOOOOOOOOOOOOOOOOkl,l0KKKKKKKKKKK0KKKKKKK0kxkk
// 0000Okxdc;cdddxxdoodxdxO0xlollxOOko,,oOOOOOOkOkkxl:..                                    .';cllloxkO0OOOOOOkkOOOOOOOOOOOkl'c0KXXXXKKKKKKKK00KKKKK00Okk
// kkxdddxkdooddddoccldooodOOdc::lok0Ol;,:okOOOOOOOOkkxo:'.                             ..';clllodxOOOkkkxxxxxkkkkOOOOOOOOkc'cOKXXNNXXKKKK00OO0KXXXXNNNXK
// dddolloxxkkxkkxlccllooldO0xl:;loxO0xdoccccoxkkkkkkkkkkkdl;..                    ..',;:clllodxkkkxxddooolllloooddddxxxxo;'lk00KXXXKXXXK0kkOkkO0KXXXXNNN
// ooodxkO0OOO00Odlcdkkkxlcx00o'.;oxO0xook0Odllcccllooddxxkkkxoc,............   .';cllllloddxxxxdddooolllllllllllllllc;,',lk00OO0KK0KXXXX0OkxxxxxkOOOOO0K
// odxkOKXNX0OkxxdooldxdocldkOkl,:dkK0dldOKKKK0Odlc:::cloodxxkkkkxolccclcc:;,;;:llooooddxxxxdddddooooollllllcccc:;,''',cxKNNX0OOKXXK0KXXXKKOkdxdlodddddod
// oloodk0KKOkdooddxxkkkddodxkOkx00kxdoox0KKKKKKKK0Oxdolccclooddddxxkkxxxxxddddddxxxxkkxxxdooll::;,,,,'.''........';cox0XXXXX0kkO0KKKXXKOOOOkkOkddxdddddd
// xolcoxO00OkxxxxxOKKKOdodxkOkxk0Od:;cokKKKKKKKKK0KKKK0koc:,,,;;;:codkOkkkkkkkkkkkkkkxdollc:;:,,:cccl:,;loolclooddddo:lkOKXKkddxkkO000OkkOO000Oxdddxxxxx
// oolldO0KXKOkkkkO0K0Oxdddxk00000kolddx0KKKKKKKK0xdkkkxxkOkdc::clc,;oxkkkOOOOOOOkkkxdl:;;;:::cccoO0K0OO0KK00KK0000OxlloldkOkxdoooxkOOOO0KK0OOOOxoodxddoo
// llclodkKXKOxkkO0KK0OkxkOO0XNWNX0kkkkkO0KKKKKKK0olxxkO0KKKKK0Okxc,':xkkOOOOOOOOkkxxxc;lo,.;ok0KKKKKKKKKKKKKK00OOOkddkOxolodddooodxk000000kxxxxxdxkOkdoc
// clodddxkOkxdddxO00OkddxkO0XXNNX0kkxxxxkkO0KKKKOo:dO00KKKKKK0OOkd:';xOkOOOOOOOOkkkkkocdo,;x0KKKKKKK00000000OOOkkkkkkkkkl:clloodxxxxk0OOkxdddkO0KKKK0kdo
// ;:lodxdoxxxxxdxO0OkdoodxkO0000000OxxxkkxxO0xoollxO000000000KKKK0OdloodkOOOOOOOOOOxlccoodk0KKKK00000OOOOkkkkkkxxxkkkOOkl,:llldkO00Oxddoooddxk0KKK0OOOkk
// ,,:cloodxkxddxk0KOxdoooddxk0KXXXKOOkkO00Okxl;coxkOOOOOOO000000K0OxxocokOOOOOOOOOOkdoxkO0KK0000OOOkkkkkkxxxxxxxxxxkOOOd;.':lloxkkOkdodddxdddxOOOkxddxdd
// ;loddddx00kddxO00kxolldkkO0XNWWNK0kkkOO0Oxdo;;dkOkkkkkkkOOOO000KKkc:dkOOOOOOOOOOOOklcdO0000OOOkkkkxxxxxxxxkxkxdooolcl;,;',llloodddlldddddolllloddolllc
// looollldO0OxodkkkxdolodxkkO0KXXX0Oxdddddddol;:dkOxxxxxxkkkkOOO000Ol:dOOOOOOOOOOOOkocdO000OOOkkkxxxkkxxxddkOxol:'.'''';c:;;:clooooolllooooc:;;;:cc::::;
// dddolc:oxxkxxxk0Oxddddxddddxxxxxxxdoolccccc;''ckkdxxxxxxxxkkkOOO0Oo:lxkOOOkkkOOOOx:;oO00OOkkkkxxxkOOkdo:;::'....',,;:c:;ll:;loddxkxdolodddol:::::;;;;:
// ooool:;:lllodxOkxxxkOOkxxddolllooolollccc:',:,'ododxxxxxxxxkkkOOOkxo:cdOOOkkOOOOOklck000OOOkkxxxkkkOd;'......'',,;;:c:;cccc::dxO000kdlloooolc::;;;;;::
// loddoollc:clloodxkO00kdoollllllcllcccccc:,':c'.''.:dxxxxkkxxxkkOOOd:lxkOOOOOOOOOOxcd000OOOOkxddkOx:;,........',;;;;::;;c::cc:lkkkkkxdoodoolllc:;;;:loo
// ddxxddoocclcllloxxOOOxlclllcclcccccccc::;,:l:'.....;dxdk0Oxxxxkkkkd;:kOkkOOOOOOOOxclOK0OOOdlc,:xd;..........',;;;;::;,:c:;:cc;lkkxxxxxkkkkOOxoc:::lool
// ooddoollllooodxkkk00Okddddoolodoolcccc:;,:lc;'''....,dlo00Okkkkkkdc:ckOkOOOOOOOOOkockKOlc:''...,''''........';;;;::;,,:::;::lc,cxxkOO0000KXXOdc:;::c::
// odxxxdoodxxddddxkkkOOOkxollodkOOkdlcc:;,:cc:;'''.....,'.lOOOOkkkkxldkOkOOOOOOOOOOkocll;......'''','''....'..,;;;;::;'';::;;:cl:,lk0XXXKOOOOOxoc:::;;;;
// clldkOxddddddddk00kxdxdollloodxkkdolc:,:c:::,'''...''.'.'cdxkOkOO0xlokOkOOOOOOOOOkkl,'......''',,;,,'....'.',;;;;;;,'';::;;;:ll,,oOKK0Okkxdolc::ccccc:
// ;::coddlllcclodkO0Oxddddoooddoolllcc:,;c:;;;,'....',,,,,..,;;;;codolokOOOOOOkkkkkkkl;,....''',,;;;;;,'...''';;;;;;;,.',::;;:;:lc';dkO0Okxdollllclooooo
// ;;;::cc::;;;:codxkkxdlooolllollc:::;',c:;:;;,'....';;;;;;,''''....:xkOOkOOOOOOkkkkkl;,..'''',,;;;;;;;,'..',,;;;;;;;,..,;:;;:;:co:'ckKKK0kdollooodkOOO0
// :::;::::::;;;:cloddolcccccclcc:::::',c:;;;;;,.....;;;;;;;;;;;,'..'lkkkkkkkOOOOkkkkkl;,..''',,;;;;;;;;;,'..,::;;;;;;'..';;;;;;::ll,'o0XX0kdlllcccoxO000
// ccc::::::::::::lodxxdllccclool:;:c,'::;;;:;;'....,;;;;;;;;;;;;'..'oOOOOkkOOkkOOOOOkl;,.'',,,;;;;;;;;;;;,'..cc;,;;;,'...,;;;;;;:clc';x0Oxlc:::clloddxxd
// ccc:::::::::::clodkOOxdolllllc:;;,.:::;;:;;;'....;;:;;;;;;;;:;'..'okxxxxkxxdddxxxxxc;,'',,,;;;;;;;;;;;;;,..,l:',;;,....';;;;:;;:lo;.:ddllccccodddxxxxd
// ::::::cc:::::::cclodxxdooooolc;;'.,c:;::;;;;'...';;;;;;;;;;;;;'..;xOkkkkkkkxxxkkkkko:,',,;;;;;;;;;;;;;;;,'..:c,';;,....',;;;;:;;:ll'.cddoolldk0000Okdd
// ;::::ccc:::::ccccclllooolccccc:,.'::;;::;;;,'...,;;;;;;;;;;::;'..;xkkOOOkkkkkOOkkOko;,',;;;;;;;;;;;;;:;;,,..,l;.,;'.....,;:;;;;;:co:.,llclooxO0KXX0xol

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BrokeBoys is ERC721Enumerable, Ownable {
    using Strings for uint256;

    event StateUpdate(bool isActive);

    string public unrevealedURI =
        "ipfs://QmcbDm9axA9TvN3T4LaZrxnurGKnc77yB7mVB6HEc9TNHC";
    string public baseURI;

    bool public isActive;

    uint256 public constant PRICE = 0.5 ether;
    uint256 public constant MAX_SUPPLY = 999;

    mapping(address => bool) private _whitelisted;

    constructor() ERC721("BrokeBoys", "BROKE") {}

    // ------------- View -------------

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : unrevealedURI;
    }

    // ------------- User Api -------------

    function publicMint() external payable onlyWhenActive onlyPaid onlyHuman {
        _mintFor(msg.sender);
    }

    function whitelistMint()
        external
        payable
        onlyWhitelisted
        onlyPaid
        onlyHuman
    {
        _mintFor(msg.sender);
    }

    // ------------- Internal -------------

    function _mintFor(address _to) internal {
        require(totalSupply() < MAX_SUPPLY, "No supply left");
        _mint(_to, totalSupply());
    }

    // ------------- Modifier -------------

    modifier onlyWhenActive() {
        require(isActive, "Sale is not active");
        _;
    }

    modifier onlyHuman() {
        require(tx.origin == msg.sender, "Contract calls not allowed");
        _;
    }

    modifier onlyWhitelisted() {
        require(_whitelisted[msg.sender], "Caller not whitelisted");
        _whitelisted[msg.sender] = false;
        _;
    }

    modifier onlyPaid() {
        require(msg.value == PRICE, "Incorrect value supplied");
        _;
    }

    // ------------- Owner -------------

    function giveAway(address[] memory users) external onlyOwner {
        for (uint256 i; i < users.length; i++) _mintFor(users[i]);
    }

    function whitelist(address[] memory users) external onlyOwner {
        for (uint256 i; i < users.length; i++) _whitelisted[users[i]] = true;
    }

    function setSaleState(bool active) external onlyOwner {
        isActive = active;
        emit StateUpdate(active);
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setUnrevealedURI(string memory _uri) external onlyOwner {
        unrevealedURI = _uri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function recoverToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner(), balance);
        require(_success, "Token could not be transferred");
    }
}
