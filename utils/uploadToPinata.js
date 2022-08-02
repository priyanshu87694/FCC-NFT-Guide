const pinataSDK = require("@pinata/sdk")
const path = require("path")
const fs = require("fs")
require("dotenv").config()

const pinata_api_key = process.env.PINATA_API_KEY
const pinata_api_secret = process.env.PINATA_API_SECRET
const pinata = pinataSDK(pinata_api_key, pinata_api_secret)

async function storeImages (imagesFilePath) {
    console.log("Uploading to Pinata...")
    const fullImagesPath = path.resolve(imagesFilePath)
    const files = fs.readdirSync(fullImagesPath)
    let responses = []
    for (fileIndex in files) {
        console.log(`Working on file index: ${fileIndex}`)
        const readableStreamForFile = fs.createReadStream(`${fullImagesPath}/${files[fileIndex]}`)
        try {
            const response = await pinata.pinFileToIPFS(readableStreamForFile)
            responses.push(response)
        } catch (error) {
            console.log(error)
        }
    }
    return { responses, files }
}

async function storeTokenUriMetaData (metaData) {
    try {
        const response = await pinata.pinJSONToIPFS(metaData)
        return response
    } catch (error) {
        console.log(error)
    }
    return null
}

module.exports = { storeImages, storeTokenUriMetaData }