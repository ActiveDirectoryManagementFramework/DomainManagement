namespace DomainManagement
{
    /// <summary>
    /// Catches three states: True, False or Undefined
    /// </summary>
    public enum TriBool
    {
        /// <summary>
        /// Represents truth
        /// </summary>
        True = 1,

        /// <summary>
        /// Represents non-truth
        /// </summary>
        False = 0,

        /// <summary>
        /// No choice was made
        /// </summary>
        Undefined = -1
    }
}
