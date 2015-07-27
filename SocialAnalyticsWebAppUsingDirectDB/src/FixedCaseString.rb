# A String class that doesn't allow String case conversion.
class FixedCaseString < String
	# Prevents lower-case conversion.
	def downcase
		# Return the current string without any modifications.
		return self
	end

	# Prevents upper-case conversion.
	def capitalize
		# Return the current string without any modifications.
		return self
	end
end