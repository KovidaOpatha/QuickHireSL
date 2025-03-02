const express = require("express");
const mongoose = require("mongoose");
const bodyParser = require("body-parser");
const cors = require("cors");

const app = express();
const PORT = 5000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MongoDB Connection
mongoose
  .connect("mongodb+srv://kovidaopathaz:hrHDidbvWWVigT5l@cluster0.de4ggus.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("Connected to MongoDB"))
  .catch((err) => console.error("MongoDB connection error:", err));

// Define the Nested Reply Schema
const reactionSchema = new mongoose.Schema({
  likes: { type: Number, default: 0 },
  likedBy: { type: [String], default: [] }
});

// Define a recursive schema for replies
const replySchema = new mongoose.Schema({
  user: { type: String, required: true },
  avatar: { type: String, required: true },
  message: { type: String, required: true },
  time: { type: String, required: true },
  reactions: { type: reactionSchema, default: () => ({ likes: 0, likedBy: [] }) },
  replies: { type: Array, default: [] }
});

// Define the Chat Schema
const chatSchema = new mongoose.Schema({
  user: { type: String, required: true },
  avatar: { type: String, required: true },
  message: { type: String, required: true },
  time: { type: String, required: true },
  replies: [replySchema],
  reactions: {
    likes: { type: Number, default: 0 },
    likedBy: { type: [String], default: [] },
  },
});

// Create the Chat Model
const Chat = mongoose.model("Community", chatSchema);

// API Endpoints
app.get("/api/chats", async (req, res) => {
  try {
    const chats = await Chat.find().sort({ _id: -1 }); // Sort by newest first
    res.json(chats);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.post("/api/chats", async (req, res) => {
  try {
    const newChat = new Chat(req.body);
    await newChat.save();
    res.status(201).json(newChat);
  } catch (err) {
    res.status(400).send(err.message);
  }
});

// Add a reply to a post
app.post("/api/chats/:id/reply", async (req, res) => {
  try {
    const postId = req.params.id;
    const reply = req.body;
    
    const post = await Chat.findById(postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }
    
    // Ensure replies has the proper structure
    if (!reply.reactions) {
      reply.reactions = { likes: 0, likedBy: [] };
    }
    if (!reply.replies) {
      reply.replies = [];
    }
    
    post.replies.push(reply);
    await post.save();
    
    res.status(201).json(reply);
  } catch (err) {
    res.status(400).send(err.message);
  }
});

// Toggle reaction (like/unlike) on a post
app.put("/api/chats/:id/react", async (req, res) => {
  try {
    const postId = req.params.id;
    const { user, liked } = req.body;
    
    const post = await Chat.findById(postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }
    
    // Update reaction
    if (liked) {
      // Add like
      if (!post.reactions.likedBy.includes(user)) {
        post.reactions.likes += 1;
        post.reactions.likedBy.push(user);
      }
    } else {
      // Remove like
      if (post.reactions.likedBy.includes(user)) {
        post.reactions.likes = Math.max(0, post.reactions.likes - 1);
        post.reactions.likedBy = post.reactions.likedBy.filter(u => u !== user);
      }
    }
    
    await post.save();
    res.status(200).json(post);
  } catch (err) {
    res.status(400).send(err.message);
  }
});

// Add a nested reply (reply to a reply)
app.post("/api/chats/:id/reply/:replyIndex/nested", async (req, res) => {
  try {
    const { id, replyIndex } = req.params;
    const nestedReply = req.body;
    
    // Ensure proper index format
    const replyIndexNum = parseInt(replyIndex);
    
    const post = await Chat.findById(id);
    if (!post || !post.replies[replyIndexNum]) {
      return res.status(404).json({ message: "Post or reply not found" });
    }
    
    // Ensure nested reply has the proper structure
    if (!nestedReply.reactions) {
      nestedReply.reactions = { likes: 0, likedBy: [] };
    }
    if (!nestedReply.replies) {
      nestedReply.replies = [];
    }
    
    // Initialize replies array if it doesn't exist
    if (!post.replies[replyIndexNum].replies) {
      post.replies[replyIndexNum].replies = [];
    }
    
    // Add the nested reply
    post.replies[replyIndexNum].replies.push(nestedReply);
    await post.save();
    
    // Return the entire post to update client state
    res.status(201).json(post);
  } catch (err) {
    console.error("Error adding nested reply:", err);
    res.status(400).send(err.message);
  }
});

// Toggle reaction on a reply
app.put("/api/chats/:id/reply/:replyIndex/react", async (req, res) => {
  try {
    const { id, replyIndex } = req.params;
    const { user, liked } = req.body;
    
    // Ensure proper index format
    const replyIndexNum = parseInt(replyIndex);
    
    const post = await Chat.findById(id);
    if (!post || !post.replies[replyIndexNum]) {
      return res.status(404).json({ message: "Post or reply not found" });
    }
    
    const reply = post.replies[replyIndexNum];
    
    // Initialize reactions if they don't exist
    if (!reply.reactions) {
      reply.reactions = { likes: 0, likedBy: [] };
    }
    
    // Update reaction
    if (liked) {
      // Add like
      if (!reply.reactions.likedBy.includes(user)) {
        reply.reactions.likes += 1;
        reply.reactions.likedBy.push(user);
      }
    } else {
      // Remove like
      if (reply.reactions.likedBy.includes(user)) {
        reply.reactions.likes = Math.max(0, reply.reactions.likes - 1);
        reply.reactions.likedBy = reply.reactions.likedBy.filter(u => u !== user);
      }
    }
    
    // Save the updated post
    await post.save();
    
    // Return the entire post to update client state
    res.status(200).json(post);
  } catch (err) {
    console.error("Error updating reply reaction:", err);
    res.status(400).send(err.message);
  }
});

// Toggle reaction on a nested reply
app.put("/api/chats/:id/reply/:replyIndex/nested/:nestedIndex/react", async (req, res) => {
  try {
    const { id, replyIndex, nestedIndex } = req.params;
    const { user, liked } = req.body;
    
    // Ensure proper index format
    const replyIndexNum = parseInt(replyIndex);
    const nestedIndexNum = parseInt(nestedIndex);
    
    const post = await Chat.findById(id);
    if (!post || !post.replies[replyIndexNum] || !post.replies[replyIndexNum].replies || !post.replies[replyIndexNum].replies[nestedIndexNum]) {
      return res.status(404).json({ message: "Post, reply, or nested reply not found" });
    }
    
    const nestedReply = post.replies[replyIndexNum].replies[nestedIndexNum];
    
    // Initialize reactions if they don't exist
    if (!nestedReply.reactions) {
      nestedReply.reactions = { likes: 0, likedBy: [] };
    }
    
    // Update reaction
    if (liked) {
      // Add like
      if (!nestedReply.reactions.likedBy.includes(user)) {
        nestedReply.reactions.likes += 1;
        nestedReply.reactions.likedBy.push(user);
      }
    } else {
      // Remove like
      if (nestedReply.reactions.likedBy.includes(user)) {
        nestedReply.reactions.likes = Math.max(0, nestedReply.reactions.likes - 1);
        nestedReply.reactions.likedBy = nestedReply.reactions.likedBy.filter(u => u !== user);
      }
    }
    
    // Save the updated post
    await post.save();
    
    // Return the entire post to update client state
    res.status(200).json(post);
  } catch (err) {
    console.error("Error updating nested reply reaction:", err);
    res.status(400).send(err.message);
  }
});

// Start the Server
app.listen(PORT, () => {console.log(`Server running on http://localhost:${PORT}`);
});