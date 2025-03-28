const { expect } = require("chai");
const ethers = require("ethers")
const { assertHardhatInvariant } = require("hardhat/internal/core/errors");

let accounts = [];
let signers = [];

let HoneyBadgerFactory;
let HoneyBadgerBaseV1;

//test suite is not completed.
describe("HoneyBadgerBaseV1 Unit Tests", function()
{
    let HoneyBadgerInstanceAddress;
    let HoneyBadgerInstanceId;

    function validate(
        res,
        expectedType,
        expectedSize,
        expectedBitCount,
    )
    {
        expect(Number(res[0])).to.equal(expectedType);
        expect(Number(res[1])).to.equal(expectedSize);
        expect(Number(res[2])).to.equal(expectedBitCount);
    }

    before(async() =>
    {
        signers = await hre.ethers.getSigners();

        for(let i = 0; i < 20; i++)
        {
            accounts[i] = await signers[i].getAddress();
        }
    
        //get contract factory for every contract we will use
        HoneyBadgerFactory = await hre.ethers.getContractFactory("HoneyBadgerBaseV1");   
    });

    it("deploys all contracts", async() =>
    {   
        HoneyBadgerBaseV1 = await HoneyBadgerFactory.deploy(accounts[0]);
    });

    it("Creates a storage space", async() =>
    {
        await HoneyBadgerBaseV1.init_create([1,1], [128, 128], false)
    });

    it("Pushes", async() => {
        await HoneyBadgerBaseV1.push(1, 0);
    });

    it("Checks storage space metadata", async() =>
    {
        let res = [];
        await HoneyBadgerBaseV1.get_storage_space_metadata(0).then((result) => {
            res = result
        })
        res.forEach(r => {
            r = Number(r)
        })

        res.map((result,index) => {
            if(index == 0) expect(Number(result)).to.equal(2);
            if(index == 1) expect(Number(result)).to.equal(2);
            if(index == 2) expect(Number(result)).to.equal(1);
            if(index == 3) expect(Number(result)).to.equal(1);
        })
    });

    it("Verifies member data", async() => {
        let res;
        await HoneyBadgerBaseV1.get_member_data(0, 0).then((result) => {
            res = result;
        })

        validate(res, 1,128,0);

        await HoneyBadgerBaseV1.get_member_data(1, 0).then((result) => {
            res = result;
        })

        validate(res, 1, 128, 128);
    });

    it("Puts values in both storage slots", async() => {
        await HoneyBadgerBaseV1.put(69, 0,1,0, "0x");
        await HoneyBadgerBaseV1.put(70, 1,1,0, "0x");
    })

    it("Gets values from both slots", async() => {
        await HoneyBadgerBaseV1.get(0,1,0, "0x").then((res) => {
            expect(Number(res)).to.equal(69)
        });

        await HoneyBadgerBaseV1.get(1,1,0, "0x").then((res) => {
            expect(Number(res)).to.equal(70)
        });
    });

    it("Inserts a new member", async() => {
        await HoneyBadgerBaseV1.insert_new_member(1, 32, 0)
    })

    it("Validates new member", async() => {
        let res;
        await HoneyBadgerBaseV1.get_member_data(2, 0).then((result) => {
            res = result;
        })

        expect(Number(res[0])).to.equal(1);
        expect(Number(res[1])).to.equal(32);
        expect(Number(res[2])).to.equal(256);
    })

    it("Insert every type, validate metadata", async() => {

        let res;

        await HoneyBadgerBaseV1.insert_new_member(2, 32, 0);
        await HoneyBadgerBaseV1.get_member_data(3, 0).then((result) => {
            res = result;
        });
        validate(res, 2, 32, 288);

        await HoneyBadgerBaseV1.insert_new_member(3, 8, 0);
        await HoneyBadgerBaseV1.get_member_data(4, 0).then((result) => {
            res = result;
        });
        validate(res, 3, 8, 320);

        await HoneyBadgerBaseV1.insert_new_member(4, 160, 0);
        await HoneyBadgerBaseV1.get_member_data(5, 0).then((result) => {
            res = result;
        });
        validate(res, 4, 160, 328);


        await HoneyBadgerBaseV1.insert_new_member(5, 256, 0);
        await HoneyBadgerBaseV1.get_member_data(6, 0).then((result) => {
            res = result;
        });
        validate(res, 5, 256, 512);

        await HoneyBadgerBaseV1.insert_new_member(6, 0, 0)

        await HoneyBadgerBaseV1.get_member_data(7, 0).then((result) => {
            res = result;
        });
        validate(res, 6, 0, 1);
        console.log("s1 data", res)
        await HoneyBadgerBaseV1.insert_new_member(6, 0, 0)

        await HoneyBadgerBaseV1.get_member_data(8, 0).then((result) => {
            res = result;
        });
        validate(res, 6, 0, 2);
        console.log("s2 data", res)
    })

    it("Puts two strings", async() => {

        await HoneyBadgerBaseV1.put_string("Hello, test!", 7, 1, 0, "0x");
        await HoneyBadgerBaseV1.put_string("Hello, world!", 8, 1, 0, "0x");

    })

    it("Gets two strings", async() => {
        await HoneyBadgerBaseV1.get_string(7, 1, 0, "0x").then((res) => {
            expect(res).to.equal("Hello, test!")
        });
        await HoneyBadgerBaseV1.get_string(8, 1, 0, "0x").then((res) => {
            expect(res).to.equal("Hello, world!")
        });
    })

    it("Creates 50 random storage spaces", async() => {

        function Generate_Type()
        {
            return 1 + Math.floor(Math.random() * 5);
        }

        function Generate_Size({type})
        {
            let rand = Math.random();
            if(type <= 2)
            {
                if(rand < .25) return 8;
                else if(rand < .5) return 16;
                else if(rand < .75) return 32;
                else return 256;
            }
            if(type == 3) return 8;
            if(type == 4) return 160;
            if(type == 5) return 256;
            if(type == 6) return 0;
        }

        for(let i = 0; i < 50; i++)
        {
            let typesAmount = 5 + Math.floor(Math.random() * 10);

            let types = [];
            let sizes = []

            for(let j = 0; j < typesAmount; j++)
            {
                types.push(Generate_Type());
                sizes.push(Generate_Size({type: types[j]}))
            }

            await HoneyBadgerBaseV1.init_create(types, sizes, false);
        }

        await HoneyBadgerBaseV1.init_create([1, 1, 1, 1, 6], [32, 32, 32, 32, 0], false);
    });

    it("Validates storage space 51", async() => {
        let res;

        await HoneyBadgerBaseV1.push(1, 51);

        await HoneyBadgerBaseV1.put(1, 0, 1, 51, "0x");
        await HoneyBadgerBaseV1.put(2, 1, 1, 51, "0x");
        await HoneyBadgerBaseV1.put(3, 2, 1, 51, "0x");
        await HoneyBadgerBaseV1.put(4, 3, 1, 51, "0x");
        await HoneyBadgerBaseV1.put_string("Hello storage space 51!", 4, 1, 51, "0x");

        await HoneyBadgerBaseV1.get(0,1,51, "0x").then((res) => {
            expect(Number(res)).to.equal(1);
        });

        await HoneyBadgerBaseV1.get(1,1,51, "0x").then((res) => {
            expect(Number(res)).to.equal(2);
        });

        await HoneyBadgerBaseV1.get(2,1,51, "0x").then((res) => {
            expect(Number(res)).to.equal(3);
        });

        await HoneyBadgerBaseV1.get(3,1,51, "0x").then((res) => {
            expect(Number(res)).to.equal(4);
        });

        await HoneyBadgerBaseV1.get_string(4,1,51, "0x").then((res) => {
            expect(res).to.equal("Hello storage space 51!");
        });
    });

    it("String stress test", async() => {

        await HoneyBadgerBaseV1.init_create([6], [0], false);
        await HoneyBadgerBaseV1.push(1, 52);

        let garble = `2941744210419248124214214912841274129410231231824104128157119231291257151
        128124124212040124912841294125712857298572891759812759182759817259817259817259871295871
        298521249871298471982749812749871291203122759872985975128414-021-4091-2094-102491248172
        2941744210419248124214214912841274129410231231824104128157119231291257151
        128124124212040124912841294125712857298572891759812759182759817259817259817259871295871
        298521249871298471982749812749871291203122759872985975128414-021-4091-2094-102491248172`

        for(let i = 0; i < 21; i++)
        {
            await HoneyBadgerBaseV1.insert_new_member(6, 0, 52);
            await HoneyBadgerBaseV1.put_string(`Storage Space ${i}${garble}`, i, 1, 52, "0x");
        }

        for(let i = 0; i < 21; i++)
        {
            await HoneyBadgerBaseV1.get_string(i, 1, 52, "0x").then((res) => {
                expect(res).to.equal(`Storage Space ${i}${garble}`);
            });
        }
    });

    it("Get_batch test", async() => {

        await HoneyBadgerBaseV1.get_batch([0,1,2,3], 1, 0, "0x").then((res) => {
            console.log(res);
        })
    });
    it("Grant permissions to account 1", async() => 
    {
        await HoneyBadgerBaseV1.update_permissions(accounts[1], [1, 2], false);
    })
    it("Uses permissions from other account", async() =>
    {
        const signer1 = HoneyBadgerBaseV1.connect(signers[1]);
        await signer1.put(6900, 0, 1, 0, "0x");
    })
    it("Validates new value is added", async() => {
        let result;

        await HoneyBadgerBaseV1.get(0,1,0, "0x").then((res) => {
            result = res;
        })

        console.log(result)
    })

    it("Creates a storage space with special access", async() => {
        await HoneyBadgerBaseV1.init_create([1,1], [256, 256], true);
        //await HoneyBadgerBaseV1.push(1, 53)

        const arg1 = "cameron warnick"
        const arg2 = "veronica von shrub"

        const arg3 = "Flangus von nudsuk"
        const arg4 = "dringus of schwab"

        const packed = ethers.solidityPacked(["string", "string"], [arg1, arg2])
        //const packed2 = ethers.solidityPacked(["string", "string"], [arg3, arg4])

        await HoneyBadgerBaseV1.put(20, 0, 1, 53, packed);

        await HoneyBadgerBaseV1.get(0, 1, 53, packed).then((r) => {
            console.log("String result", r)
        });
    });

    it("Creates a storage space with special access - string", async() => {

        await HoneyBadgerBaseV1.init_create([6,6], [0,0], true);
        //await HoneyBadgerBaseV1.push(1, 54);

        const arg1 = "cameron warnick";
        const arg2 = "susie sandalpecker";

        const packed = ethers.solidityPacked(["string", "string"], [arg1, arg2]);
        await HoneyBadgerBaseV1.put_string("Hello mister", 0, 1, 54, packed);
        await HoneyBadgerBaseV1.get_string(0,1,54, packed).then((res) => {
            console.log("String2 result: ", res)
        })

    })



});