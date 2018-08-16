/**
 * @file DNote.sol
 * @author sufay
 */

pragma solidity ^0.4.23;


import {StringHandler as SH} from "./lib/StringHandler.sol";


/**
 * @title DNote contract which is a decentralized note app
 */
contract DNote {
    // Note contains the basic note information
    struct Note{
        address author;
        string title;
        string content;
        string tag;
        uint time;
    }

    // WrappedNote wraps the note and provides some other properties
    struct WrappedNote {
        Note note; // the origin note
        bool valid; // indicate if the note is valid
    }
    
    mapping (uint => WrappedNote) public notes; // notes maps id to WrappedNote
    mapping (address => mapping (uint => bool)) public authorIds; // authorIds maps an address to ids
    mapping (address => uint) public authorCountMap; // authorCountMap maps an address to its note count
    mapping (address => mapping (bytes32 => bool)) public authorTitleMap; // a map used to check if a title of a author exists
    mapping (bytes32 => uint) public tagCountMap; // tagCountMap maps a string to the number of the notes tagged by the string
    
    uint public noteCount; // note count
    uint public lastId; // the last id

    address public owner; // the contract owner

    /**
     * @dev an event which indicates a note was created
     * @param _author the note author
     * @param _id the note id
     */
    event NoteCreated(address indexed _author, uint indexed _id);

    /**
     * @dev an event which indicates a note was deleted
     * @param _author the note author
     * @param _id the note id
     */
    event NoteDeleted(address indexed _author, uint indexed _id);

    /**
     * @dev an event which indicates a note was modified
     * @param _author the note author
     * @param _id the note id
     * @param _type the modification type. 1 means title,
     *              2 means content and 0 means both.
     */
    event NoteModified(address indexed _author, uint indexed _id, uint8 indexed _type);
    
    // only owner is allowed
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // only author is permitted
    modifier onlyAuthor(uint _id) {
        require(msg.sender == notes[_id].note.author);
        _;
    }
    
    // assert the title and content are empty neither
    modifier notEmpty(string _title, string _content) {
        require(!SH.empty(_title) && !SH.empty(_content));
        _;
    }
    
    // assert the title is not duplicated by the author
    modifier notDuplicated(string _title) {
        require(!authorTitleMap[msg.sender][keccak256(bytes(_title))]);
        _;
    }
    
    // assert an id exists
    modifier exists(uint _id) {
        require(notes[_id].valid);
        _;
    }
    
    // assert the given title is different from the exsiting ones by the author
    modifier newTitle(string _newTitle) {
        require (
            !SH.empty(_newTitle) &&
            !authorTitleMap[msg.sender][keccak256(bytes(_newTitle))]
        );

        _;
    }
    
    // assert the given content is different from the exsiting ones by the author
    modifier newContent(uint _id, string _newContent) {
        require (
            !SH.empty(_newContent) &&
            !SH.equal(notes[_id].note.content, _newContent)
        );

        _;
    }
    
    /**
     * @dev constructor
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev fallback function
     */
    function() public {
        // noop
    }

    /**
     * @dev get the total number of notes
     */
    function getNoteCount() public view returns (uint) {
        return noteCount;
    }

    /**
     * @dev get the note count by the author
     * @param _author the author to be searched
     */
    function getNoteCountByAuthor(address _author) public view returns (uint) {
        return authorCountMap[_author];
    }

    /**
     * @dev get the note of the specified id
     * @param _id the destination id
     */
    function getNoteById(uint _id) public view returns (address, string, string, string, uint) {
        Note storage note = notes[_id].note;
        return (note.author, note.title, note.content, note.tag, note.time);
    }
    
    /**
     * @dev get the note count of the specified tag
     * @param _tag the specified tag
     */
    function getTagCount(string _tag) public view returns (uint) {
        return tagCountMap[keccak256(bytes(_tag))];
    }

    /**
     * @dev create a note
     * @param _title the title
     * @param _content the content
     * @param _tag the tag
     */
    function createNote(string _title, string _content, string _tag) 
        public
        notEmpty(_title, _content)
        notDuplicated(_title)
        returns (bool)
    {
        // increase the lastId
        lastId++;
        
        // create a new note
        Note memory note = Note(msg.sender, _title, _content, _tag, block.timestamp);
        notes[lastId] = WrappedNote(note, true);
        
        // call the related handler
        _onCreated(lastId, _title, _tag);

        return true;
    }
    
    /**
     * @dev delete a note by id
     * @param _id the destination id to be deleted
     */
    function deleteNote(uint _id) public exists(_id) onlyAuthor(_id) returns (bool) {
        // get the note data
        string memory title = notes[_id].note.title;
        string memory tag = notes[_id].note.tag;
        
        // delete the destination note
        delete notes[_id];
        
        // call the related handler
        _onDeleted (_id, title, tag);

        return true;
    }

    /**
     * @dev modify the title of a note by id
     * @param _id the destination id to be modified
     * @param _newTitle the new title
     */
    function modifyTitle(uint _id, string _newTitle)
        public
        exists(_id)
        onlyAuthor(_id)
        newTitle(_newTitle)
        returns (bool)
    {
        // get the original title
        string memory oriTitle = notes[_id].note.title;

        // modify the title
        notes[_id].note.title = _newTitle;
        
        // call the related handler
        _onModified(_id, oriTitle, _newTitle, 1); // 1 refers to title type
        
        return true;
    }

    /**
     * @dev modify the content of a note by id
     * @param _id the destination id to be modified
     * @param _newContent the new content
     */
    function modifyContent(uint _id, string _newContent)
        public
        exists(_id)
        onlyAuthor(_id)
        newContent(_id, _newContent)
        returns (bool)
    {
        // modify the content
        notes[_id].note.content = _newContent;

        // call the related handler
        _onModified(_id, "", "", 2); // 2 refers to content type
        
        return true;
    }
    
    /**
     * @dev modify the title and content of a note by id
     * @param _id the destination id to be modified
     * @param _newTitle the new title
     * @param _newContent the new content
     */
    function modifyNote(uint _id, string _newTitle, string _newContent)
        public
        exists(_id)
        onlyAuthor(_id)
        newTitle(_newTitle)
        newContent(_id, _newContent)
        returns (bool)
    {
        // get the original title
        string memory oriTitle = notes[_id].note.title;

        // modify the title and content
        notes[_id].note.title = _newTitle;
        notes[_id].note.content = _newContent;

        // call the related handler
        _onModified(_id, oriTitle, _newTitle, 0); // 0 refers to title and content type
        
        return true;
    }

    /**
     * @dev a handler to be called when a note is created
     * @param _id the id of the new note
     * @param _title the title of the new note
     * @param _tag the tag of the new note
     */
    function _onCreated(uint _id, string _title, string _tag) internal {
        // handle authorIds
        authorIds[msg.sender][_id] = true;

        // handle authorCountMap
        authorCountMap[msg.sender]++;

        // handle authorTitleMap
        authorTitleMap[msg.sender][keccak256(bytes(_title))] = true;

        // handle tagCountMap
        if (!SH.empty(_tag)) {
            tagCountMap[keccak256(bytes(_tag))]++;
        }

        // increase the note count
        noteCount++;

        // fire the NoteCreated event
        emit NoteCreated(msg.sender, _id);
    }

     /**
     * @dev a handler to be called when a note is deleted
     * @param _id the id of the deleted note
     * @param _title the title of the deleted note
     * @param _tag the tag of the deleted note
     */
    function _onDeleted(uint _id, string _title, string _tag) internal {
        // handle authorIds
        authorIds[msg.sender][_id] = false;

        // handle authorCountMap
        authorCountMap[msg.sender]--;

        // handle authorTitleMap
        authorTitleMap[msg.sender][keccak256(bytes(_title))] = false;

        // handle tagCountMap
        if (!SH.empty(_tag)) {
            tagCountMap[keccak256(bytes(_tag))]--;
        }

        // decrease the note count
        noteCount--;

        // fire the NoteDeleted event
        emit NoteDeleted(msg.sender, _id);
    }

    /**
     * @dev a handler to be called when a note is modified
     * @param _id the id of the modified note
     * @param _old the old data of the modified part
     * @param _new the new data of the modified part
     */
    function _onModified(uint _id, string _old, string _new, uint8 _type) internal {
        // handle if title is modified
        if (_type == 0 || _type == 1) {
            authorTitleMap[msg.sender][keccak256(bytes(_old))] = false;
            authorTitleMap[msg.sender][keccak256(bytes(_new))] = true;
        }

        // fire the NoteModified event
        emit NoteModified(msg.sender, _id, _type);
    }
}