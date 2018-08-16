var DNote = artifacts.require("DNote");


contract("DNote", function (accounts) {
    it("should create a note", function () {
        var contract;

        var title = "my first blockchain note";
        var content = "experience the on-chain note";
        var tag = "blockchain";

        return DNote.deployed().then(instance => {
            contract = instance;
            return instance.createNote(title, content, tag);
        }).then(result => {
            return contract.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[0], accounts[0], "the address is wrong");
            assert.equal(note[1], title, "the title is wrong");
            assert.equal(note[2], content, "the content is wrong");
            assert.equal(note[3], tag, "the tag is wrong");
        });
    });

    it("should modify an existing note", function () {
        var contract;
        var newTitle = "new title";
        var newContent = "new content";

        return DNote.deployed().then(instance => {
            contract = instance;
            return instance.modifyNote(1, "new title", "new content");
        }).then(result => {
            return contract.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[1], newTitle, "the title is wrong");
            assert.equal(note[2], newContent, "the content is wrong'");
        });
    });

    it("should get a note", function () {
        var contract;

        return DNote.deployed().then(instance => {
            contract = instance;
            return instance.getNoteCount.call();
        }).then(count => {
            assert.equal(count.toNumber(), 1, "the count is wrong");
        });
    });

    it("should delete a note", function () {
        var contract;

        return DNote.deployed().then(instance => {
            contract = instance;
            return instance.deleteNote(1);
        }).then(result => {
            return contract.getNoteById.call(1);
        }).then(note => {
            assert.equal(note[1], "", "the title is wrong");
            assert.equal(note[2], "", "the content is wrong");
            assert.equal(note[3], "", "the tag is wrong");
        });
    });

    it("should get zero note", function () {
        var contract;

        return DNote.deployed().then(instance => {
            contract = instance;
            return instance.getNoteCount.call();
        }).then(count => {
            assert.equal(count.toNumber(), 0, "the count is wrong");
        });
    });
});
