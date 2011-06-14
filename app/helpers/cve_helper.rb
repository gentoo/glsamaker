module CveHelper
  # Converts a bit mask to a condition usable by AR
  def view_mask_to_condition(mask)
    conditions = []

    conditions << 'state = "NEW"' if mask & 1 == 1
    conditions << 'state = "ASSIGNED"' if mask & 2 == 2
    conditions << 'state = "LATER"' if mask & 4 == 4
    conditions << 'state = "NFU"' if mask & 8 == 8
    conditions << 'state = "INVALID"' if mask & 16 == 16

    conditions.join(' OR ')
  end
end
