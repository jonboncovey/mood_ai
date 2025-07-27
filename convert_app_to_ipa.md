# Convert Runner.app.zip to .ipa File

## Method 1: Manual Conversion

1. **Download and extract** `Runner.app.zip` from CodeMagic
2. **Create folder structure**:
   ```
   mkdir Payload
   cp -r Runner.app Payload/
   zip -r Runner.ipa Payload/
   ```
3. **Upload `Runner.ipa`** to Firebase Test Lab

## Method 2: Using Finder (macOS)

1. **Extract** `Runner.app.zip` 
2. **Create new folder** called `Payload`
3. **Move `Runner.app`** into the `Payload` folder
4. **Compress the `Payload` folder** to ZIP
5. **Rename** `Payload.zip` to `Runner.ipa`
6. **Upload to Firebase Test Lab**

## Method 3: Command Line (if you have macOS/Linux access)

```bash
# Extract the zip
unzip Runner.app.zip

# Create IPA structure
mkdir Payload
mv Runner.app Payload/
zip -r Runner.ipa Payload/

# Now you have Runner.ipa ready for Test Lab
```

## Firebase Test Lab Upload

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Test Lab**
4. Click **"Run a test"**
5. Upload your `Runner.ipa` file
6. Select iOS devices to test
7. Choose **"Robo test"** for automatic testing
8. Run the test! 