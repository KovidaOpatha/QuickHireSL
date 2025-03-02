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
    const chats = await Chat.find();
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

// Start the Server
app.listen(PORT, () => {console.log(`Server running on http://localhost:${PORT}`);
});
