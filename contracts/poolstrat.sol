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
        uint256 allocMultiply;  // pool에 할당된 배수(STiger 지급용)
        uint256 lastRewardBlock;  // Reward가 지급된 블록 ( 컴파운드 된 블록 )
        uint256 accSTigerPerShare;  // Share당 STiger 누적량
        address strat;  // compound를 해줄 컨트랙트 주소
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /* 모든 식은 *100이 되어있음 (.1 -> 10, .05 ->5)
    ** 
    */

    uint256 startBlock = 9999999999999;  // 시작할 블록
    uint256 totalMultiply = 0;

    address public STiger = 0x2D35515397521cd5B48c7E000EBE535Dd2e93a73;
    uint256 public STigerMaxSupply = 1000000e18;  // 1million!
    uint256 public ownerSTigerReward = 100;  // 1%
    

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    /*
    function approvePool(IBEP20 _want) public {
        _want.approve(address(this), 100000);
    }
    token.approve(이 계약의 주소, 수량) 이런 식으로 web3 상에서 구현하기.. tx.origin이 아니라 불가
    */
    

    function getAllowance (IBEP20 _want) public view returns (uint256) {
        return _want.allowance(tx.origin, address(this));
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
    function add(
        IBEP20 _want,
        uint256 _allocMultiply,
        address _strat
    ) public onlyOwner {
        
        uint256 lastRewardBlock = 
            block.number > startBlock ? block.number : startBlock;
        totalMultiply = totalMultiply.add(_allocMultiply);

        poolInfo.push(
            PoolInfo({
                want: _want,
                allocMultiply: _allocMultiply,
                lastRewardBlock: lastRewardBlock,
                accSTigerPerShare: 0,
                strat: _strat
            })
        );
    }

    // poolInfo[_pid]의 allocMultiply를 allocNewMultiply로 바꾼다.
    function MultiplyUpdate(
        uint256 _pid,
        uint256 _allocNewMulltiply
    ) public onlyOwner {

        totalMultiply = totalMultiply.sub(poolInfo[_pid].allocMultiply).add(
            _allocNewMulltiply
        );
        poolInfo[_pid].allocMultiply = _allocNewMulltiply;
    }


    function getRewardSTiger(
        uint256 _fromBlockNum,
        uint256 _toBlockNum
    ) public view returns(uint256) {
        if (IBEP20(STiger).totalSupply() >= STigerMaxSupply) {
            return 0;
        }
        
        return _toBlockNum.sub(_fromBlockNum);
    }

    // 지급해야할 STiger의 양이 보유량보다 많다면 보유량 전체를 줌
    function safeSTigerTransfer(address _to, uint256 _STigerAmt) internal {
        uint256 STigerBal = IBEP20(STiger).balanceOf(address(this));
        if (_STigerAmt > STigerBal) {
            IBEP20(STiger).transfer(_to, STigerBal);
        } else {
            IBEP20(STiger).transfer(_to, _STigerAmt0;)
        }
    }

    function deposit(uint256 _pid, uint256 _wantAmt) public {

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.shares > 0) {
            uint256 pending =
                user.shares.mul(pool.accSTigerPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeSTigerTransfer(msg.sender, pending);
            }
        }
        
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