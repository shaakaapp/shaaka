import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../constants/location_data.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';


class ProfilePage extends StatefulWidget {
  final bool isCompletingProfile;

  const ProfilePage({
    super.key,
    this.isCompletingProfile = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();

  String? _selectedGender;
  String? _selectedCountry;
  String? _selectedState;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _imagePicker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _isEditing = widget.isCompletingProfile;
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
      return;
    }

    final result = await ApiService.getProfile(userId);
    if (result['success'] == true && mounted) {
      setState(() {
        _userProfile = result['data'];
        _populateFields();
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Failed to load profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _populateFields() {
    if (_userProfile != null) {
      _fullNameController.text = _userProfile!.fullName;
      _mobileController.text = _userProfile!.mobileNumber;
      _selectedGender = _userProfile!.gender;
      _addressController.text = _userProfile!.addressLine ?? '';
      _cityController.text = _userProfile!.city ?? '';
      
      _selectedCountry = _userProfile!.country;
      _selectedState = _userProfile!.state;
        
      // Verify values exist in our static list
      if (_selectedCountry != null && !LocationData.countryStateMap.containsKey(_selectedCountry)) {
        _selectedCountry = null;
        _selectedState = null;
      } else if (_selectedCountry != null && _selectedState != null) {
        final states = LocationData.countryStateMap[_selectedCountry];
        if (states != null && !states.contains(_selectedState)) {
          _selectedState = null;
        }
      }
      _pincodeController.text = _userProfile!.pincode ?? '';
      
      // Parse location from URL if available

    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImage = image;
          _profileImageBytes = bytes;
        });

        // Upload image to Cloudinary
        setState(() {
          _isLoading = true;
        });

        final uploadResult = await ApiService.uploadImage(_profileImage!);

        setState(() {
          _isLoading = false;
        });

        if (uploadResult['success'] == true) {
          // Update profile with new image URL
          if (_userProfile != null) {
            final updateResult = await ApiService.updateProfile(
              _userProfile!.id!,
              {'profile_pic_url': uploadResult['url']},
            );
            if (updateResult['success'] == true) {
              setState(() {
                _userProfile = updateResult['data'];
                _profileImage = null; // Clear local file after upload
                _profileImageBytes = null;
              });
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  uploadResult['error']?['error'] ?? 'Failed to upload image',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _updateProfile() async {
    if (_userProfile == null) return;

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'full_name': _fullNameController.text.trim(),
      'gender': _selectedGender,
      'address_line': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'state': _selectedState,
      'country': _selectedCountry,
      'pincode': _pincodeController.text.trim().isEmpty
          ? null
          : _pincodeController.text.trim(),
    };

    final result = await ApiService.updateProfile(_userProfile!.id!, userData);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      setState(() {
        _userProfile = result['data'];
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (widget.isCompletingProfile) {
        // Navigate to Login Page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['error']?['error'] ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading && _userProfile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Failed to load profile'),
        ),
      );
    }

    return Scaffold(
      // backgroundColor: AppTheme.softBeige,
      appBar: AppBar(
        title: Text(widget.isCompletingProfile ? 'Complete Profile' : 'Profile'),
        automaticallyImplyLeading: !widget.isCompletingProfile,
        elevation: 0,
        actions: [
          if (!_isEditing)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            )
          else if (!widget.isCompletingProfile)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _updateProfile,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.check,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Added extra bottom padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Picture
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppAnimations.medium,
              curve: AppAnimations.defaultCurve,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _profileImageBytes != null
                            ? Image.memory(
                                _profileImageBytes!,
                                fit: BoxFit.cover,
                              )
                            : _userProfile!.profilePicUrl != null
                                ? Image.network(
                                    _userProfile!.profilePicUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Theme.of(context).textTheme.bodyMedium!.color!,
                                  ),
                      ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: AppTheme.accentTerracotta,
                          shape: const CircleBorder(),
                          elevation: 4,
                          child: InkWell(
                            onTap: _isLoading ? null : _pickImage,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // User Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                        filled: !_isEditing,
                        fillColor: !_isEditing ? Colors.grey[200] : null,
                      ),
                      items: _genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: _isEditing
                          ? (String? newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Category: ${_userProfile!.category}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Address Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        prefixIcon: Icon(Icons.public),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: LocationData.countryStateMap.keys
                          .map((country) => DropdownMenuItem(
                                value: country,
                                child: Text(country),
                              ))
                          .toList(),
                      onChanged: _isEditing
                          ? (val) {
                              setState(() {
                                _selectedCountry = val;
                                _selectedState = null; // Reset state when country changes
                              });
                            }
                          : null,
                      validator: (value) {
                         if (value == null || value.isEmpty) {
                          return 'Please select a country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.map),
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _selectedCountry != null
                          ? LocationData.countryStateMap[_selectedCountry]!
                              .map((state) => DropdownMenuItem(
                                    value: state,
                                    child: Text(state),
                                  ))
                              .toList()
                          : [],
                      onChanged: _isEditing
                          ? (val) {
                              setState(() {
                                _selectedState = val;
                              });
                            }
                          : null,
                        validator: (value) {
                         if (value == null || value.isEmpty) {
                          return 'Please select a state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Pincode',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
              const SizedBox(height: 8),
              if (!widget.isCompletingProfile)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _populateFields();
                    });
                  },
                  child: const Text('Cancel'),
                ),
            ] else ...[
              // Logout Button
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await StorageService.clearAll();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  icon: Icon(Icons.logout_outlined, color: Theme.of(context).colorScheme.error),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

