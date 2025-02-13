// const mongoose = require('mongoose');

// const userSchema = new mongoose.Schema({
//     email: { type: String, required: true, unique: true },
//     password: { type: String, required: true },
//     role: { type: String, enum: ['student', 'employer'], default: null },
//     studentDetails: {
//         fullName: { type: String },
//         leavingAddress: { type: String },
//         dateOfBirth: { type: Date },
//         mobileNumber: { type: String },
//         nicNumber: { type: String }
//     },
//     jobOwnerDetails: {
//         shopName: { type: String },
//         shopLocation: { type: String },
//         shopRegisterNo: { type: String }
//     }
// }, { timestamps: true });

// module.exports = mongoose.model('User', userSchema);














// const mongoose = require('mongoose');

// const userSchema = new mongoose.Schema({
//     email: { type: String, required: true, unique: true },
//     password: { type: String, required: true },
//     role: { type: String, enum: ['student', 'employer'], default: null },
//     studentDetails: {
//         fullName: { type: String },
//         leavingAddress: { type: String },
//         dateOfBirth: { type: Date },
//         mobileNumber: { type: String },
//         nicNumber: { type: String }
//     },
//     jobOwnerDetails: {
//         shopName: { type: String },
//         shopLocation: { type: String },
//         shopRegisterNo: { type: String }
//     }
// }, { timestamps: true });

// module.exports = mongoose.model('User', userSchema);

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['student', 'employer'], default: 'student' },
    studentDetails: {
        fullName: { type: String },
        leavingAddress: { type: String },
        dateOfBirth: { type: Date },
        mobileNumber: { type: String },
        nicNumber: { type: String }
    },
    jobOwnerDetails: {
        shopName: { type: String },
        shopLocation: { type: String },
        shopRegisterNo: { type: String }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);


// const mongoose = require('mongoose');

// const userSchema = new mongoose.Schema({
//     email: { type: String, required: true, unique: true },
//     password: { type: String, required: true },
//     role: { type: String, enum: ['student', 'employer'], default: 'student' },
//     studentDetails: {
//         fullName: { type: String },
//         leavingAddress: { type: String },
//         dateOfBirth: { type: Date },
//         mobileNumber: { type: String },
//         nicNumber: { type: String }
//     },
//     jobOwnerDetails: {
//         shopName: { type: String },
//         shopLocation: { type: String },
//         shopRegisterNo: { type: String }
//     }
// }, { timestamps: true });

// module.exports = mongoose.model('User', userSchema);
