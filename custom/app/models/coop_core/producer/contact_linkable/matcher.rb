# Candidate lookup + ambiguity handling for
# CoopCore::Producer::ContactLinkable.auto_link_contact. Strong signals only
# (design §8.3): phone (AR 9-marker variants via CoopCore::PhoneNumber) or a
# normalized 11-digit CUIT match. Zero or multiple candidates -> no link.
class CoopCore::Producer::ContactLinkable::Matcher
  def initialize(producer_class, contact)
    @producer_class = producer_class
    @contact = contact
  end

  def link
    case candidates.size
    when 1
      candidates.first.link_contact(contact)
    when 0
      false
    else
      log_conflict
      false
    end
  end

  private

  attr_reader :producer_class, :contact

  def candidates
    @candidates ||= (phone_candidates + cuit_candidates).uniq
  end

  def phone_candidates
    return [] if contact.phone_number.blank?

    variants = ::CoopCore::PhoneNumber.ar_variants(contact.phone_number)
    producer_class.where(account_id: contact.account_id, primary_phone: variants).to_a
  end

  def cuit_candidates
    return [] if normalized_cuit.blank?

    producer_class.where(account_id: contact.account_id, cuit: normalized_cuit).to_a
  end

  def normalized_cuit
    raw = contact.additional_attributes&.dig('cuit')
    return nil if raw.blank?

    digits = ::CoopCore::Producer::Cuit.normalize(raw)
    digits.length == 11 ? digits : nil
  end

  # TODO(S7): record `link_conflict` in the coop_core_events outbox once it
  # ships (design §8.5) -- logging is the interim signal until then.
  def log_conflict
    Rails.logger.warn(
      "[CoopCore] link_conflict account_id=#{contact.account_id} contact_id=#{contact.id} " \
      "candidate_producer_ids=#{candidates.map(&:id).sort}"
    )
  end
end
