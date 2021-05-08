pragma solidity 0.7.6;

import "./BEP20.sol";
import "./Ownable.sol";
import "./SafeBEP20.sol";

contract Pool1 is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;


    struct UserInfo {

        uint256 shares; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IBEP20 want; // Address of the want token.
        uint256 accSTigerPerShare;
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    address public STiger = 0x2D35515397521cd5B48c7E000EBE535Dd2e93a73;
    uint256 public ownerSTigerReward = 100;
    

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function approvePool(IBEP20 _want) public {
        _want.approve(address(this), 100000);
    }
    
    function getAllowance (IBEP20 _want) public view returns (uint256) {
        return _want.allowance(tx.origin, address(this));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function add(IBEP20 _want) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                want: _want,
                accSTigerPerShare: 0
            })
        );
    }

    function deposit(uint256 _pid, uint256 _wantAmt) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (_wantAmt > 0) {
            pool.want.safeTransferFrom(
                address(msg.sender),
                address(this),
                _wantAmt
            );

            user.shares = user.shares.mul(pool.accSTigerPerShare).div(1e12);
            emit Deposit(msg.sender, _pid, _wantAmt);
        }
    }

    function withdraw(uint _pid, uint256 _wantAmt) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 wantAmt;
        
        uint256 wantLockedTotal = pool.want.balanceOf(address(this));
        if (_wantAmt < wantLockedTotal) {
            wantAmt = wantLockedTotal;
        } else {
            wantAmt = _wantAmt;
        }
        pool.want.safeTransfer(address(msg.sender), _wantAmt);
        user.rewardDebt = user.shares.mul(pool.accSTigerPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _wantAmt);
    }




}