package chat.simplex.common.platform

import androidx.compose.ui.platform.ClipboardManager
import androidx.compose.ui.platform.UriHandler
import chat.simplex.common.model.CIFile
import chat.simplex.common.model.CryptoFile
import chat.simplex.common.model.MsgContent

expect fun UriHandler.sendEmail(subject: String, body: CharSequence)

expect fun ClipboardManager.shareText(text: String)
expect fun shareFile(text: String, fileSource: CryptoFile)
expect fun openFile(fileSource: CryptoFile)

// Android stores received media in system gallery; desktop keeps files in app storage.
expect fun autoSaveReceivedMedia(ciFile: CIFile, msgContent: MsgContent)
