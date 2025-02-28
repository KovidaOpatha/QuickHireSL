const express = require("express");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// Feedback Schema & Model
const FeedbackSchema = new mongoose.Schema({
  rating: { type: Number, required: true },
  feedback: { type: String, required: true },
  date: { type: Date, default: Date.now }
});


// API Endpoint to Save Feedback
app.post("/feedback", async (req, res) => {
  try {
    console.log("Received Feedback Data:", req.body);
    const { rating, feedback } = req.body;

    if (!rating || !feedback) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    const newFeedback = new Feedback({ rating, feedback });
    await newFeedback.save();

    console.log("Feedback Saved Successfully");
    res.status(201).json({ message: "Feedback submitted successfully" });
  } catch (err) {
    console.error("Error Saving Feedback:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// API Endpoint to Get All Feedback
app.get("/feedbacks", async (req, res) => {
  try {
    const feedbacks = await Feedback.find().sort({ date: -1 });
    res.status(200).json(feedbacks);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

