/**
 * Supabase Content Upload Script
 *
 * This script uploads all manifest and lesson content files to Supabase Storage.
 * Run this script after setting up your Supabase project.
 *
 * Usage: node scripts/upload-to-supabase.js
 */

import { createClient } from "@supabase/supabase-js"
import fs from "fs"
import path from "path"

// Supabase configuration
const SUPABASE_URL = "https://jnimcsiushnsonyvfrtt.supabase.co"
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY

if (!SUPABASE_SERVICE_KEY) {
  console.error("Error: SUPABASE_SERVICE_ROLE_KEY environment variable is required")
  console.error("Get it from: Supabase Dashboard > Settings > API > service_role key")
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

const BUCKET_NAME = "content"
const CONTENT_DIR = "./supabase_content"

/**
 * Upload a file to Supabase Storage
 */
async function uploadFile(localPath, storagePath) {
  try {
    const fileContent = fs.readFileSync(localPath, "utf-8")

    // Validate JSON
    JSON.parse(fileContent)

    const { data, error } = await supabase.storage.from(BUCKET_NAME).upload(storagePath, fileContent, {
      contentType: "application/json",
      upsert: true, // Overwrite if exists
    })

    if (error) {
      console.error(`Failed to upload ${storagePath}:`, error.message)
      return false
    }

    console.log(`Uploaded: ${storagePath}`)
    return true
  } catch (err) {
    console.error(`Error processing ${localPath}:`, err.message)
    return false
  }
}

/**
 * Recursively find all JSON files in a directory
 */
function findJsonFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir)

  for (const file of files) {
    const filePath = path.join(dir, file)
    const stat = fs.statSync(filePath)

    if (stat.isDirectory()) {
      findJsonFiles(filePath, fileList)
    } else if (file.endsWith(".json")) {
      fileList.push(filePath)
    }
  }

  return fileList
}

/**
 * Main upload function
 */
async function main() {
  console.log("Starting Supabase content upload...\n")

  // Check if content directory exists
  if (!fs.existsSync(CONTENT_DIR)) {
    console.error(`Error: Content directory not found: ${CONTENT_DIR}`)
    process.exit(1)
  }

  // Find all JSON files
  const jsonFiles = findJsonFiles(CONTENT_DIR)
  console.log(`Found ${jsonFiles.length} JSON files to upload\n`)

  let successCount = 0
  let failCount = 0

  for (const localPath of jsonFiles) {
    // Convert local path to storage path
    // e.g., ./supabase_content/manifests/global_manifest.json -> manifests/global_manifest.json
    const storagePath = localPath.replace(CONTENT_DIR + "/", "").replace(CONTENT_DIR + "\\", "")

    const success = await uploadFile(localPath, storagePath)
    if (success) {
      successCount++
    } else {
      failCount++
    }
  }

  console.log("\n--- Upload Summary ---")
  console.log(`Success: ${successCount}`)
  console.log(`Failed: ${failCount}`)
  console.log(`Total: ${jsonFiles.length}`)

  if (failCount === 0) {
    console.log("\nAll files uploaded successfully!")
    console.log(`\nPublic URL base: ${SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/`)
  } else {
    console.log("\nSome files failed to upload. Check the errors above.")
    process.exit(1)
  }
}

main().catch(console.error)
