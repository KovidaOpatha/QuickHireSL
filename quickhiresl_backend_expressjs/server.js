const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");

const app = express();
app.use(express.json());
app.use(cors());

// MongoDB Connection
mongoose.connect("mongodb+srv://kovidaopathaz:hrHDidbvWWVigT5l@cluster0.de4ggus.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0", {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => console.log("MongoDB Connected"))
  .catch(err => console.log(err));

// Feedback Schema & Model
const FeedbackSchema = new mongoose.Schema({
  rating: { type: Number, required: true },
  feedback: { type: String, required: true },
  date: { type: Date, default: Date.now }
});

const Feedback = mongoose.model("Feedback", FeedbackSchema);

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

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

mongoose.set('debug', true);
