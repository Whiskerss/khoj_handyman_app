const otpModel = require('../models/otp.model');
const WorkerModel = require('../models/worker.model');
const AuthService = require('../services/auth.service');


exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        const user = await AuthService.checkUser(email);

        if (!user) {
            return next('User does not exist.');
        }

        const isMatch = await user.comparePassword(password);
        if (isMatch === false) {
            return next('Invalid Password!');
        }

        const worker = await WorkerModel.findOne({ _id: user._id });

        res.status(200).json({ user, worker });

    } catch (error) {
        return next(error);
    }
}

exports.register = async (req, res, next) => {
    try {
        const { firstName, lastName, dob, role, email, phone, password } = req.body;

        console.log(role);

        const existingUser = await AuthService.checkUser(email);

        if (existingUser) {
            return next('User already exists.');
        }
        const user = await AuthService.registerUser(firstName, lastName, dob, role, email, phone, password);

        let worker; // Initialize the worker variable

        if (role == 'worker') {
            const workerInstance = new WorkerModel({ _id: user._id });
            worker = await workerInstance.save(); // Save the worker instance and assign it to the variable
        }
        res.status(200).json({ user, worker });
    } catch (error) {
        return next(error);
    }
}

exports.checkEmail = async (req, res, next) => {
    try {
        const { email } = req.body;
        const existingUser = await AuthService.checkUser(email);

        if (existingUser) {
            return next('User already exists.');
        }
        res.status(200).json({ existingUser });

    } catch {
        return next(error);
    }
}

exports.getRegisOTP = async (req, res, next) => {
    try {
        const { email, firstName, lastName } = req.body;

        const user = await AuthService.checkUser(email);

        if (user) {
            return next('User already exists!');
        }

        const userName = `${firstName} ${lastName}`;

        await AuthService.sendOTP(email, 'registration', userName, res, next);

    } catch (error) {
        return next(error);
    }
}

exports.getResetOTP = async (req, res, next) => {
    try {
        const { email } = req.body;

        const user = await AuthService.checkUser(email);

        if (!user) {
            return next('User does not exist.');
        }

        const userName = `${user.firstName} ${user.lastName}`;

        await AuthService.sendOTP(email, 'reset password', userName);

        res.status(200).json('OTP sent.');

    } catch (error) {
        return next(error);
    }
}

exports.verifyOTP = async (req, res, next) => {
    try {
        const email = req.params.email;
        const otp = req.params.otp;
        const purpose = req.params.purpose;
        console.log('ok');
        const verify = await AuthService.checkOTP(email, otp, purpose);

        if (!verify) {
            return next('Incorrect OTP.');
        }
        console.log('otp verified');
        res.status(200).json({ msg: 'OTP verified.' });

    } catch (error) {
        return next(error);
    }
}
