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
mongoose.connect("mongodb+srv://kovidaopathaz:hrHDidbvWWVigT5l@cluster0.de4ggus.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("Connected to MongoDB"))
  .catch((err) => console.error("MongoDB connection error:", err));

// Define the Chat Schema
const chatSchema = new mongoose.Schema({
    user: { type: String, required: true },
    avatar: { type: String, required: true },
    message: { type: String, required: true },
    time: { type: String, required: true },
    replies: [
      {
        user: String,
        avatar: String,
        message: String,
        time: String,
        reactions: {
          likes: { type: Number, default: 0 },
          likedBy: { type: [String], default: [] },
        },
        replies: { type: Array, default: [] },
      },
    ],
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
    
    const post = await Chat.findById(id);
    if (!post || !post.replies[replyIndex]) {
      return res.status(404).json({ message: "Post or reply not found" });
    }
    
    // Add nested reply
    if (!post.replies[replyIndex].replies) {
      post.replies[replyIndex].replies = [];
    }
    
    post.replies[replyIndex].replies.push(nestedReply);
    await post.save();
    
    res.status(201).json(nestedReply);
  } catch (err) {
    res.status(400).send(err.message);
  }
});

// Toggle reaction on a reply
app.put("/api/chats/:id/reply/:replyIndex/react", async (req, res) => {
  try {
    const { id, replyIndex } = req.params;
    const { user, liked } = req.body;
    
    const post = await Chat.findById(id);
    if (!post || !post.replies[replyIndex]) {
      return res.status(404).json({ message: "Post or reply not found" });
    }
    
    const reply = post.replies[replyIndex];
    
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
    
    await post.save();
    res.status(200).json(post);
  } catch (err) {
    res.status(400).send(err.message);
  }
});

// Start the Server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});