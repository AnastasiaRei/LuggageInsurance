module.exports = async function (promise, errorMessage) {
    try {
        await promise;
        throw null;
    }
    catch (error) {
        assert(error, "Expected an error but did not get one");
        assert.equal(error.reason, errorMessage);
    }
}