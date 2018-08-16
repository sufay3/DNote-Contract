var DNoteDelegator = artifacts.require("DNoteDelegator");
var DNote = artifacts.require("DNote")
var abiEncode = require("./utils").abiEncode


contract("DNoteDelegator", function (accounts) {
    var dnote;

    it("should have deployed the DNote contract and keep clean", function () {
        DNote.deployed().then(instance => {
            dnote = instance;
            return instance.getNoteCount.call();
        }).then(count => {
            assert.equal(count, 0, "the count is wrong");
        });
    });

    it("should set the DNote address successfully", function () {
        var delegator;

        return DNoteDelegator.deployed().then(instance => {
            delegator = instance;
            return instance.setDNote(dnote.address);
        }).then(() => {
            return delegator.DNote.call();
        }).then(address => {
            assert.equal(address, dnote.address, "the address is wrong");
        });
    });

    it("should create a note", function () {
        var delegator;

        var title = "my first blockchain note2";
        var content = "experience the on-chain note2";
        var tag = "blockchain2";

        return DNoteDelegator.deployed().then(instance => {
            delegator = instance;
            return instance.sendTransaction({ data: abiEncode(DNote, "createNote", [title, content, tag]) });
        }).then(result => {
            return dnote.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[0], delegator.address, "the address is wrong");
            assert.equal(note[1], title, "the title is wrong");
            assert.equal(note[2], content, "the content is wrong");
            assert.equal(note[3], tag, "the tag is wrong");
        });
    });

    it("should modify an existing note", function () {
        var delegator;

        var newTitle = "new title";
        var newContent = "new content";

        return DNoteDelegator.deployed().then(instance => {
            delegator = instance;
            return instance.sendTransaction({ data: abiEncode(DNote, "modifyNote", [1, newTitle, newContent]) });
        }).then(result => {
            return dnote.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[1], newTitle, "the title is wrong");
            assert.equal(note[2], newContent, "the content is wrong'");
        });
    });

    it("should get a note", function () {
        return DNoteDelegator.deployed().then(instance => {
            return dnote.getNoteCount.call();
        }).then(count => {
            assert.equal(count.toNumber(), 1, "the count is wrong");
        });
    });

    it("should delete a note", function () {
        var delegator;

        return DNoteDelegator.deployed().then(instance => {
            delegator = instance;
            return instance.sendTransaction({ data: abiEncode(DNote, "deleteNote", [1]) });
        }).then(result => {
            return dnote.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[1], "", "the title is wrong");
            assert.equal(note[2], "", "the content is wrong");
            assert.equal(note[3], "", "the tag is wrong");
        });
    });

    it("should get zero note", function () {
        return DNoteDelegator.deployed().then(instance => {
            return dnote.getNoteCount.call();
        }).then(count => {
            assert.equal(count.toNumber(), 0, "the count is wrong");
        });
    });
});
